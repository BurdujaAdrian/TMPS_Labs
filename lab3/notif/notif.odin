package notif

import "core:fmt"
import sl "core:slice"
import str "core:strings"
import "core:time"
import "core:time/datetime"


// #facade
when true {
	// @service for notif
	@(private)
	NotificationService :: struct {
		bases:     map[string]INotif,
		set_get:   map[string]struct {
			set: set_proc,
			get: get_proc,
		},
		sent_list: [dynamic]^INotif,
	}
	create_batch_cc_encrypted_notification :: proc(
		type, message, priority: string,
		recipient: [dynamic]string,
		encrypt := simple_encrypt,
	) -> ^INotif {

		service := get_instance()

		regular := create_batch_cc_notification(type, message, priority, recipient)
		if regular == nil do return nil

		for &notif in (cast(^Batch_Notif)regular).notifs {
			_n := cast(^Notif)notif
			notif = create_encrypted_notification(_n.type, _n.recipient, _n.message, _n.priority)
		}

		return cast(^INotif)(regular)
	}

	create_batch_cc_notification :: proc(
		type, message, priority: string,
		recipients: [dynamic]string,
	) -> ^INotif {

		service := get_instance()

		base: INotif = service.bases["Batch"]
		notif_base: INotif = service.bases["Notif"]

		notifs := make([dynamic]^INotif)
		for rec in recipients {
			append(&notifs, new_clone(Notif{notif_base, type, rec, message, priority}))
		}
		return cast(^INotif)new_clone(Batch_Notif{base, notifs})
	}


	// Encrypted notification creation
	create_encrypted_notification :: proc(
		type, recipient, message, priority: string,
		encrypt := simple_encrypt,
	) -> ^INotif {
		service := get_instance()

		regular := create_notification(type, recipient, message, priority)
		if regular == nil do return nil

		set_msg, get_msg := expand_values(service.set_get["Notif"])

		base := service.bases["Notif"]
		encrypted := new_clone(Encrypted_Notif{base, regular, get_msg, set_msg, encrypt})

		return cast(^INotif)(encrypted)
	}

	create_notification :: proc(type, recipient, message, priority: string) -> ^INotif {

		service := get_instance()

		base: INotif = service.bases["Notif"]
		return cast(^INotif)new_clone(Notif{base, type, recipient, message, priority})
	}
	send_any_notif :: proc(notif: ^INotif) {
		service := get_instance()
		notif->send(false)
		append(&service.sent_list, notif)
		fmt.println("Total notifications sent:", len(service.sent_list))
	}

	get_sent_notifs :: proc() -> []^INotif {
		service := get_instance()
		return sl.clone(service.sent_list[:])
	}

	free_sent_nofits :: proc() {
		service := get_instance()
		for notif in service.sent_list {
			notif->cleanup()
		}
	}

	get_instance :: #force_inline proc() -> ^NotificationService {
		@(static) notif_service: ^NotificationService
		if notif_service == nil {
			fmt.println("New singleton created")
			notif_service = new(NotificationService)
			notif_service.bases["Batch"] = INotif {
				send    = batch_send,
				cleanup = batch_free,
			}
			notif_service.bases["Notif"] = INotif {
				send = send_notif,
				cleanup = proc(self: ^INotif) {
					free(cast(^Notif)self)
				},
			}
			notif_service.bases["Encrypted"] = INotif {
				send    = send_encrypted,
				cleanup = cleanup_encrypted,
			}
			return notif_service
		}

		fmt.println("Reusing singleton")
		return notif_service
	}
}
set_proc :: #type proc(self: ^INotif, _: string)
get_proc :: #type proc(self: ^INotif) -> string

// #decorator
@(private)
Encrypted_Notif :: struct {
	using base: INotif,
	wrapped:    ^INotif,
	get_msg:    get_proc,
	set_msg:    set_proc,
	encrypt:    proc(_: string) -> string,
}

send_encrypted :: proc(self: ^INotif, cleanup: bool) {
	self := cast(^Encrypted_Notif)self
	plain_text := self->get_msg()
	crypt_text := self.encrypt(plain_text)
	self->set_msg(crypt_text)
	self.wrapped->send(cleanup)
}
cleanup_encrypted :: proc(self: ^INotif) {
	self := cast(^Encrypted_Notif)self
	self.wrapped->cleanup()
	free(self)
}

// #composite
@(private)
Batch_Notif :: struct {
	using base: INotif,
	notifs:     [dynamic]^INotif,
}

new_batch :: proc(notifs: [dynamic]^INotif) -> ^Batch_Notif {

	return new_clone(Batch_Notif{send = batch_send, notifs = notifs})
}

batch_send :: proc(self: ^INotif, cleanup: bool) {
	self := cast(^Batch_Notif)self

	for not in self.notifs {
		not->send(cleanup)
	}

	if cleanup {
		free(self)
	}
}
batch_free :: proc(self: ^INotif) {
	self := cast(^Batch_Notif)self
	for not in self.notifs {
		not->cleanup()
	}
	free(self)
}
// @notifs
@(private)
Notif :: struct {
	using base:                         INotif,
	type, recipient, message, priority: string,
}

INotif :: struct {
	send:      proc(_: ^INotif, _: bool),
	cleanup:   proc(_: ^INotif),
	timestamp: datetime.Date,
}
@(private)
send_notif :: proc(notif: ^INotif, free_up: bool = true) {
	fmt.println("Sending notification...")
	fmt.println("Notification sent!")

	// free up
	if free_up do notif->cleanup()
}


@(private)
Builder :: struct {
	using payload: Notif,
}

new_builder :: #force_inline proc() -> (b: Builder) {
	b.payload.send = send_notif
	b.payload.cleanup = proc(self: ^INotif) {
		self := cast(^Notif)self
		free(self)
	}
	return
}


set_type :: #force_inline proc(self: ^Builder, $type: string) {
	fmt.println("Adding type:" + type)
	self.type = type
}

set_recipient :: #force_inline proc(self: ^Builder, $recipient: string) {
	fmt.println("Adding recipient:" + recipient)
	self.recipient = recipient
}

set_message :: #force_inline proc(self: ^Builder, $msg: string) {
	fmt.println("Adding message:" + msg)
	self.message = msg
}

set_priority :: #force_inline proc(self: ^Builder, $prio: string) {
	fmt.println("Adding priority:" + prio)
	self.priority = prio
}


build :: proc(self: ^Builder) -> (^Notif, bool) #optional_ok {
	if self.type == "" || self.recipient == "" || self.message == "" {
		fmt.eprintln("Type,recipient and message are required")
		return nil, false
	}

	err: datetime.Error
	self.timestamp, err = datetime.components_to_date(time.date(time.now()))

	if err != nil {
		fmt.eprintln("Error while formatting components:", err)
		return nil, false
	}
	return new_clone(self.payload), true
}

clone :: proc(self: ^Notif) -> (^Notif, bool) {
	timestamp, err := datetime.components_to_date(time.date(time.now()))
	if err != nil {
		fmt.eprintln("Error while formatting components:", err)
		return nil, false
	}

	return new_clone(Notif {
			type = str.clone(self.type),
			message = str.clone(self.message),
			recipient = str.clone(self.recipient),
			priority = str.clone(self.priority),
			timestamp = timestamp,
			send = self.send,
			cleanup = proc(self: ^INotif) {
				self := cast(^Notif)self
				delete(self.type)
				delete(self.type)
				delete(self.message)
				delete(self.recipient)
				delete(self.priority)
				free(self)
			},
		}), true

}


create_email_notif :: #force_inline proc($rec, $subj: string) -> (^Notif, bool) {
	builder: Builder
	set_type(&builder, "EMAIL")
	set_recipient(&builder, rec)
	set_message(&builder, "Email:" + subj)
	set_priority(&builder, "MEDIUM")

	return build(&builder)
}

create_sms_notif :: #force_inline proc($rec, $title: string) -> (^Notif, bool) {
	builder: Builder
	set_type(&builder, "SMS")
	set_recipient(&builder, rec)
	set_message(&builder, "SMS:" + title)
	set_priority(&builder, "HIGH")

	return build(&builder)
}

create_push_notif :: #force_inline proc($rec, $title: string) -> (^Notif, bool) {
	builder: Builder
	set_type(&builder, "PUSH")
	set_recipient(&builder, rec)
	set_message(&builder, "Push:" + title)
	set_priority(&builder, "LOW")

	return build(&builder)
}

create_urgent_notif :: #force_inline proc($type, $rec, $title: string) -> (^Notif, bool) {
	builder: Builder
	set_type(&builder, type)
	set_recipient(&builder, rec)
	set_message(&builder, title)
	set_priority(&builder, "LOW")

	return build(&builder)
}

// @misc
simple_encrypt :: proc(msg: string) -> string {
	encrypted := make([]u8, len(msg))
	for char, i in msg {
		char := u8(char)
		if char >= 'a' && char <= 'z' {
			encrypted[i] = 'a' + ((char - 'a' + 3) % 26)
		} else if char >= 'A' && char <= 'Z' {
			encrypted[i] = 'A' + ((char - 'A' + 3) % 26)
		} else {
			encrypted[i] = u8(char)
		}
	}
	return string(encrypted)
}
