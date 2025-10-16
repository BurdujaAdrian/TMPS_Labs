package main

import "core:fmt"
import "notif"

main :: proc() {
	// #demo singleton
	fmt.println("\n\n==========\nSingleton:\n==========\n")
	service := notif.get_instance()

	// #demo factory
	fmt.println("\n\n==========\nUsing factory procedures:\n==========\n")
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

	// #demo builder
	fmt.println("\n\n==========\nUsing the builder:\n==========\n")
	template_b := notif.new_builder()
	notif.set_type(&template_b, "EMAIL")
	notif.set_recipient(&template_b, "template@mail.com")
	notif.set_message(&template_b, "Lorem Ipsum dolorem")
	notif.set_priority(&template_b, "MEDIUM")
	template, _ := notif.build(&template_b)

	fmt.println("\n\n==========\nShowcasing the prototype:\n==========\n")
	fmt.printfln("Original: %#v", template^)

	// #demo prototype
	cloned, _ := notif.clone(template)

	fmt.printfln("Cloned: %#v", cloned)

	for notification in notif.get_sent_notifs(service) {
		fmt.printfln("%#v", notification)
	}

	fmt.println("\n\n==========\nEnsuring the singleton works as expected\n==========\n")
	assert(service == notif.get_instance())

	fmt.println("\n\n==========\nSuccess\n==========\n")

}
