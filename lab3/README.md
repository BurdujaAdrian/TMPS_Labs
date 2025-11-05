# Structural Design Patterns


## Author: Burduja Adrian

----

## Objectives:

1. Study and understand the Structural Design Patterns.
2. As a continuation of the previous laboratory work, think about the functionalities that your system will need to provide to the user.
3. Implement some additional functionalities using structural design patterns.


## Used Design Patterns: 

* composite
* decorator
* facade

## Implementation

I wrote a messeging library. It provides a messeging system and procedures to
create,manage and send notifycations.

I also modified the previous implementation by factoring the send,cleanup logic into a separate interface `INotif`

```odin
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
```

This struct allows the user to send multiple notifications to multiple
recipients. Both it and the simple Notif struct implement the 
INotif interface so they can be used homogeneously. 

```odin
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
```

This struct wrapps an existing INotif with encryption when sending. It requres methods
for getting and setting messeges since different INotif might have this member in 
different places in the struct and putting `messege` in the interface seemed like a bad
idea for future extension.

```odin
// #facade
// @service for notif
@(private)
NotificationService :: struct {
	bases:     map[string]INotif,
	sent_list: [dynamic]^INotif,
}
create_batch_cc_encrypted_notification :: proc(
	type, message, priority: string,
	recipient: [dynamic]string,
	encrypt := simple_encrypt,
) -> ^INotif {
	regular := create_batch_cc_notification(type, message, priority, recipient)
	if regular == nil do return nil
	for &notif in (cast(^Batch_Notif)regular).notifs do notif = encrypted_notif(notif)
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
	for rec in recipients do append(&notifs, new_clone(Notif{notif_base, type, rec, message, priority}))
	return cast(^INotif)new_clone(Batch_Notif{base, notifs})
}
create_encrypted_notification :: proc(
	type, recipient, message, priority: string,
	encrypt := simple_encrypt,
) -> ^INotif {
	regular := create_notification(type, recipient, message, priority)
	if regular == nil do return nil
	encrypted := encrypted_notif(regular, get_msg = proc(self: ^Encrypted_Notif) -> (msg: string) {
			wrapped := cast(^Notif)self.wrapped
			return wrapped.message
		}, set_msg = proc(self: ^Encrypted_Notif, msg: string) {
			wrapped := cast(^Notif)self.wrapped
			wrapped.message = msg
		}, encrypt = encrypt)
	return cast(^INotif)(encrypted)
}
create_notification :: proc(type, recipient, message, priority: string) -> ^INotif {
	service := get_instance()
	base: INotif = service.bases["Notif"]
	return cast(^INotif)new_clone(Notif{base, type, recipient, message, priority})
}
```

The NoficiationService singleton was extended to also act as the facade for the 
creation and sending of various types of notifications(Notif,Batch or Encrypted).

## Demo program

This is a demo, showcasing the library and the patterns that are used:
```odin
package main

import "core:fmt"
import "notif"

main :: proc() {

	notifications := make([dynamic]^notif.INotif)
	notif_builder := notif.new_builder()
	notif.set_type(&notif_builder, "Email")
	notif.set_message(&notif_builder, "Send this to all of you")
	notif.set_recipient(&notif_builder, "Amy")
	copy := notif.build(&notif_builder)

	notif.set_recipient(&notif_builder, "Bill")
	copy2 := notif.build(&notif_builder)

	notif.set_recipient(&notif_builder, "Carl")
	copy3 := notif.build(&notif_builder)

	// demo composite
	batch_notif := notif.new_batch([dynamic]^notif.INotif{copy, copy2, copy3})
	append(&notifications, batch_notif)

	// demo decorator & facade
	encrypted_4 := notif.create_encrypted_notification("Email", "Denis", "Secret", "High")
	append(&notifications, encrypted_4)

	full_batch := notif.new_batch(notifications)

	notif.send_any_notif(full_batch)
}
```

Ouput of the demo:
```
Adding type:Email
Adding message:Send this to all of you
Adding recipient:Amy
Adding recipient:Bill
Adding recipient:Carl
New singleton created
Reusing singleton
Reusing singleton
Sending notification...
Notification sent!
Sending notification...
Notification sent!
Sending notification...
Notification sent!
Sending notification...
Notification sent!
Total notifications sent: 1
```

## Conclusions
In this laboratory I successfully implemented 3 structural design patterns:
composite, decorator and facade in order to further extend the functionality
of the notification system. The composite pattern allows me to group notifications
together and send them all at the same time as well as treating a batch notification
as any other notification. The decorator pattern allowed me to add extra behavior to notifications by simply wrapping the original object.
to notifications by simply wrapping the original object. The facade pattern simplified
the usage of all of the above patterns by providing a streamlined interface.
