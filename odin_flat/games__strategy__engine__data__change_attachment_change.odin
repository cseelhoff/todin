package game

import "core:fmt"
import "core:strings"

Change_Attachment_Change :: struct {
	using change: Change,
	attached_to:     ^Attachable,
	attachment_name: string,
	new_value:       rawptr,
	old_value:       rawptr,
	property:        string,
	clear_first:     bool,
}
// Java owners covered by this file:
//   - games.strategy.engine.data.ChangeAttachmentChange

// Synthetic constructor lambda: `name -> name.replaceAll("ttatch", "ttach")`
// from `ChangeAttachmentChange(Attachable, String, Object, Object, String, boolean)`.
change_attachment_change_lambda_new_0 :: proc(property: string) -> string {
	result, _ := strings.replace_all(property, "ttatch", "ttach")
	return result
}

change_attachment_change_get_attachment_name :: proc(self: ^Change_Attachment_Change) -> string {
	return self.attachment_name
}

// Java: ChangeAttachmentChange(Attachable, @Nullable String, Object, Object, String, boolean)
// Canonical 6-arg constructor; the 3-arg and 4-arg overloads delegate here.
change_attachment_change_new_canonical :: proc(
	attachable: ^Attachable,
	attachment_name: string,
	new_value: rawptr,
	old_value: rawptr,
	property: string,
	clear_first: bool,
) -> ^Change_Attachment_Change {
	self := new(Change_Attachment_Change)
	// Optional.ofNullable(attachmentName).map(name -> name.replaceAll("ttatch", "ttach")).orElse(null)
	if len(attachment_name) > 0 {
		self.attachment_name = change_attachment_change_lambda_new_0(attachment_name)
	} else {
		self.attachment_name = ""
	}
	self.attached_to = attachable
	self.new_value = new_value
	self.old_value = old_value
	self.property = property
	self.clear_first = clear_first
	return self
}

// Java: ChangeAttachmentChange(IAttachment attachment, Object newValue, String property)
//   this(attachment.getAttachedTo(), attachment.getName(), newValue,
//        DefaultAttachment.copyPropertyValue(attachment.getPropertyOrThrow(property).getValue()),
//        property, false);
change_attachment_change_new :: proc(
	attachment: ^I_Attachment,
	new_value: rawptr,
	property: string,
) -> ^Change_Attachment_Change {
	old_value := mutable_property_get_value(
		i_attachment_get_property_or_throw(attachment, property),
	)
	return change_attachment_change_new_canonical(
		i_attachment_get_attached_to(attachment),
		i_attachment_get_name(attachment),
		new_value,
		old_value,
		property,
		false,
	)
}

// Java: ChangeAttachmentChange(IAttachment attachment, Object newValue, String property, boolean clearFirst)
//   this(attachment.getAttachedTo(), attachment.getName(), newValue,
//        DefaultAttachment.copyPropertyValue(attachment.getPropertyOrThrow(property).getValue()),
//        property, clearFirst);
change_attachment_change_new_with_clear_first :: proc(
	attachment: ^I_Attachment,
	new_value: rawptr,
	property: string,
	clear_first: bool,
) -> ^Change_Attachment_Change {
	old_value := mutable_property_get_value(
		i_attachment_get_property_or_throw(attachment, property),
	)
	return change_attachment_change_new_canonical(
		i_attachment_get_attached_to(attachment),
		i_attachment_get_name(attachment),
		new_value,
		old_value,
		property,
		clear_first,
	)
}

// Java: protected void perform(GameState data) —
// resolves the named attachment on `attached_to`, optionally resets the
// property, applies `new_value`, and on success busts the TechTracker
// cache when the affected attachment is a Tech / TechAbility attachment.
// An InvalidValueException returned from the setter is rethrown as an
// IllegalStateException-equivalent panic with the same formatting Java
// uses.
change_attachment_change_perform :: proc(self: ^Change_Attachment_Change, data: ^Game_State) {
	_ = data
	attachment := attachable_get_attachment(self.attached_to, self.attachment_name)
	attachment_property := i_attachment_get_property_or_throw(attachment, self.property)
	if self.clear_first {
		mutable_property_reset_value(attachment_property)
	}
	if err, ok := mutable_property_set_value(
		attachment_property,
		self.new_value,
	).(^Mutable_Property_Invalid_Value_Exception); ok && err != nil {
		panic(fmt.aprintf(
			"failed to set value '%v' on property '%s' for attachment '%s' associated with '%v': %s",
			self.new_value, self.property, self.attachment_name, self.attached_to, err.message,
		))
	}
	// Java: if (attachment instanceof TechAttachment) ... else if (attachment instanceof TechAbilityAttachment) ...
	// I_Attachment carries no kind discriminator; the attachment_name uniquely
	// identifies these two engine attachment types in TripleA's data model
	// (the same pattern is used by GameDataEvent.lookupEvent). We dispatch
	// on the canonical names and reinterpret_cast the underlying concrete
	// pointer to fetch its GameData / TechTracker.
	if self.attachment_name == "techAttachment" {
		tech_attachment := cast(^Tech_Attachment)attachment
		tech_tracker_clear_cache(
			game_data_get_tech_tracker(
				game_data_component_get_data(&tech_attachment.default_attachment.game_data_component),
			),
		)
	} else if self.attachment_name == TECH_ABILITY_ATTACHMENT_NAME {
		tech_ability_attachment := cast(^Tech_Ability_Attachment)attachment
		tech_tracker_clear_cache(
			game_data_get_tech_tracker(
				game_data_component_get_data(&tech_ability_attachment.default_attachment.game_data_component),
			),
		)
	}
}

