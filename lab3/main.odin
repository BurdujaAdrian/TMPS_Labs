#+feature dynamic-literals
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
