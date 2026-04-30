package game

Casualty_Order_Of_Losses :: struct {}

@(private="file")
casualty_order_of_losses_ool_cache: map[string][dynamic]^Casualty_Order_Of_Losses_Amphib_Type

casualty_order_of_losses_clear_ool_cache :: proc() {
	clear(&casualty_order_of_losses_ool_cache)
}
