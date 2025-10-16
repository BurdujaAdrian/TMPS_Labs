package notif

import "core:fmt"
import str "core:strings"
import "core:time"
import "core:time/datetime"


// @notifs
@(private)
Notif :: struct {
	type, recipient, message, priority: string,
	timestamp:                          datetime.Date,
}

@(private)
send :: proc(notif: ^Notif, free_up: bool = true) {
	fmt.println("Sending notification...")
	fmt.println("Notification sent!")

	// free up
	if free_up do free(notif)
}


// #builder
@(private)
Builder :: struct {
	using payload: Notif,
}

new_builder :: #force_inline proc() -> (b: Builder) {return}


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

build :: proc(self: ^Builder) -> (^Notif, bool) {
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

// #prototype pattern: clone function
clone :: proc(self: ^Notif) -> (^Notif, bool) {
	timestamp, err := datetime.components_to_date(time.date(time.now()))
	if err != nil {
		fmt.eprintln("Error while formatting components:", err)
		return nil, false
	}
	return new_clone(
			Notif {
				type = str.clone(self.type),
				message = str.clone(self.message),
				recipient = str.clone(self.recipient),
				priority = str.clone(self.priority),
				timestamp = timestamp,
			},
		),
		true

}


//#factory
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
	set_type(&builder, "PUSH")
	set_recipient(&builder, rec)
	set_message(&builder, "Push:" + title)
	set_priority(&builder, "LOW")

	return build(&builder)
}

// #singleton
get_instance :: #force_inline proc() -> ^NotificationService {
	@(static) notif_service: ^NotificationService
	if notif_service == nil {
		fmt.println("New singleton created")
		notif_service = new(NotificationService)
		return notif_service
	}

	fmt.println("Reusing singleton")
	return notif_service
}

// @service for notif
@(private)
NotificationService :: struct {
	sent_list: [dynamic]^Notif,
}

send_notif :: proc(service: ^NotificationService, notif: ^Notif) {
	send(notif, false)
	append(&service.sent_list, notif)

	fmt.println("Total notifications sent:", len(service.sent_list))
}

import sl "core:slice"
get_sent_notifs :: proc(service: ^NotificationService) -> []^Notif {
	return sl.clone(service.sent_list[:])
}

free_sent_nofits :: proc(service: ^NotificationService) {
	for notif in service.sent_list {
		free(notif)
	}
}
