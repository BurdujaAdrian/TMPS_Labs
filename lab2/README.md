# Creational Design Patterns


## Author: Burduja Adrian

----

## Objectives:

* Get familiar with the Creational DPs;
* Choose a specific domain;
* Implement at least 3 CDPs for the specific domain;


## Used Design Patterns: 

* Singleton
* Builder
* Prototype
* Factory


## Implementation

I wrote a messeging library. It provides a messeging system and procedures to
create,manage and send notifycations.

```odin
// #singleton
get_instance :: #force_inline proc() -> ^NotificationService {
    @(static) notif_service: ^NotificationService
	if notif_service == nil {
		notif_service = new(NotificationService)
		return notif_service
	}
	return notif_service
}
@(private)
NotificationService :: struct {sent_list: [dynamic]^Notif}
```

The notification system is contained in a singleton `notif_service` that is initialized
the first time `get_innstance` is called. Any subsequent call will simply return the
already existing one.

The notifications are managed through the fallowing procedures:
```odin
send_notif :: proc(service: ^NotificationService, notif: ^Notif) {
    /* implementation */}

import sl "core:slice"
get_sent_notifs :: proc(service: ^NotificationService) -> []^Notif {
	return sl.clone(service.sent_list[:])
}

free_sent_nofits :: proc(service: ^NotificationService) {
	for notif in service.sent_list {
		free(notif)
	}
}
```

Notifications are a private struct which describes the necesarry information to create
and send a notification:
```odin
@(private)
Notif :: struct {
	type, recipient, message, priority: string,
	timestamp:                          datetime.Date,
}

@(private)
send :: proc(notif: ^Notif, free_up: bool = true) {
    // dummy implementation
	fmt.println("Sending notification...")
	fmt.println("Notification sent!")
	if free_up do free(notif)
}
```

To help build the notifications, the user of the library can utilise the Builder:
```odin
@(private)
Builder :: struct {
	using payload: Notif,
}
new_builder :: #force_inline proc() -> (b: Builder) {return}
set_type :: #force_inline proc(self: ^Builder, $type: string) {self.type = type}
set_recipient :: #force_inline proc(self: ^Builder, $recipient: string) {self.recipient = recipient}
set_message :: #force_inline proc(self: ^Builder, $msg: string) {self.message = msg}
set_priority :: #force_inline proc(self: ^Builder, $prio: string) {self.priority = prio}
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
```

The procedure `build` will then output the corresponding notification.

In order to not duplicate code too much, it's possible to create a "template" and clone
and modify to create a new notification:
```odin
clone :: proc(self: ^Notif) -> (^Notif, bool) {
	timestamp, err := datetime.components_to_date(time.date(time.now()))
	if err != nil {
		fmt.eprintln("Error while formatting components:", err)
		return nil, false
	}
	return new_clone( Notif {
		type = str.clone(self.type),
		message = str.clone(self.message),
		recipient = str.clone(self.recipient),
		priority = str.clone(self.priority),
		timestamp = timestamp,
			},
		),true
}
```

Certain notifications must have a certain form/shape, for that purpose factory
procedures are provided. They use the builder to create the notification. Each of them
take care of taking the important information as input, and filling in the blanks with
the correct default values:
```odin
create_email_notif :: #force_inline proc($rec, $subj: string) -> (^Notif, bool) {
	builder: Builder
	set_type(&builder, "EMAIL")
	set_recipient(&builder, rec)
	set_message(&builder, "Email: %s" + subj)
	set_priority(&builder, "MEDIUM")

	return build(&builder)
}
create_sms_notif :: #force_inline proc($rec, $title: string) -> (^Notif, bool) {
    /* implemetation */
	return build(&builder)
}
create_push_notif :: #force_inline proc($rec, $title: string) -> (^Notif, bool) {
    /* implemetation */
	return build(&builder)
}
create_urgent_notif :: #force_inline proc($type, $rec, $title: string) -> (^Notif, bool) {
    /* implemetation */
	return build(&builder)
}
```

## Demo program

This is a demo, showcasing the library and the patterns that are used:
```odin
package main

import "core:fmt"
import "notif"

main :: proc() {
	// obtaining singleton
	service := notif.get_instance()

    // using factory procedures
	if email_notif, ok := notif.create_email_notif("jonndoe@mail.com", "Welcome to our service");
	   ok {
		notif.send_notif(service, email_notif)
	}

	if sms_notif, ok := notif.create_sms_notif("+123456789", "Your login code: 454"); ok {
		notif.send_notif(service, sms_notif)
	}

	if push_notif, ok := notif.create_push_notif("user123", "New messege"); ok {
		notif.send_notif(service, push_notif)
	}

    // utilizing the builder
	template_b := notif.new_builder()
	notif.set_type(&template_b, "EMAIL")
	notif.set_recipient(&template_b, "template@mail.com")
	notif.set_message(&template_b, "Lorem Ipsum dolorem")
	notif.set_priority(&template_b, "MEDIUM")
	template, _ := notif.build(&template_b)

	fmt.printfln("Original: %#v", template^)

    // cloning the template using the prototype pattern
	cloned, _ := notif.clone(template)

	fmt.printfln("Cloned: %#v", cloned^)

    // showcase that the cloning is succesfull
	for notification in notif.get_sent_notifs(service) {
		fmt.printfln("%#v", notification)
	}

    // ensure that the singleton behaves as expected
	assert(service == notif.get_instance())

}
```

Ouput of the demo:
```


==========
Singleton:
==========

New singleton created


==========
Using factory procedures:
==========

Sending notification...
Notification sent!
Total notifications sent: 1
Sending notification...
Notification sent!
Total notifications sent: 2
Sending notification...
Notification sent!
Total notifications sent: 3


==========
Using the builder:
==========



==========
Showcasing the prototype:
==========

Original: Notif{
        type = "EMAIL",
        recipient = "template@mail.com",
        message = "Lorem Ipsum dolorem",
        priority = "MEDIUM",
        timestamp = Date{
                year = 2025,
                month = 10,
                day = 16,
        },
}
Cloned: &Notif{
        type = "EMAIL",
        recipient = "template@mail.com",
        message = "Lorem Ipsum dolorem",
        priority = "MEDIUM",
        timestamp = Date{
                year = 2025,
                month = 10,
                day = 16,
        },
}
&Notif{
        type = "EMAIL",
        recipient = "jonndoe@mail.com",
        message = "Email: %sWelcome to our service",
        priority = "MEDIUM",
        timestamp = Date{
                year = 2025,
                month = 10,
                day = 16,
        },
}
&Notif{
        type = "SMS",
        recipient = "+123456789",
        message = "SMS: %sYour login code: 454",
        priority = "HIGH",
        timestamp = Date{
                year = 2025,
                month = 10,
                day = 16,
        },
}
&Notif{
        type = "PUSH",
        recipient = "user123",
        message = "Push: %sNew messege",
        priority = "LOW",
        timestamp = Date{
                year = 2025,
                month = 10,
                day = 16,
        },
}


==========
Ensuring the singleton works as expected
==========

Reusing singleton


==========
Success
==========
```

## Conclusions
This laboratory successfully implemented four creational design patterns in a notification system using the 
Odin programming language. The Singleton pattern ensured a single notification service instance, the Builder 
pattern provided flexible notification construction, the Prototype pattern enabled object cloning for templates, 
and Factory procedures offered predefined notification types. All objectives were achieved, demonstrating 
practical understanding of how creational patterns solve different object creation problems in software design. 
The implementation shows how these patterns work together to create a flexible and maintainable notification 
library.



