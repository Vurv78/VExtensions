/** @noSelfInFile **/
/*
	_________      ______            __   ______
   / ____/__ \    /_  __/___  ____  / /  / ____/___  ________
  / __/  __/ /     / / / __ \/ __ \/ /  / /   / __ \/ ___/ _ \
 / /___ / __/     / / / /_/ / /_/ / /  / /___/ /_/ / /  /  __/
/_____//____/    /_/  \____/\____/_/   \____/\____/_/   \___/
	This is a tool that will be able to be used on an e2 chip, && that chip will be able
		to run based on actions you make with the tool.
*/

import { Cooldown } from "../../../vlib/Cooldown";
import * as VNet from "../../../vlib/Net";

declare const TOOL: any;
6
TOOL.Category		= "VExtensions"
TOOL.Name			= "E2 Controller"
//TOOL.Command		= null
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if (CLIENT) {
	language.Add( "Tool.e2controller.name", "E2 Controller");
	language.Add( "Tool.e2controller.desc", "Allows the selected e2 to execute on controls used from the tool.");
	language.Add( "Tool.e2controller.left", "Left Click Action");
	language.Add( "Tool.e2controller.right", "Right Click Action, or Select Chip");
	language.Add( "Tool.e2controller.reload", "Reload Action");
	TOOL.Information = [ "left", "right", "reload" ];
}

let selectedChip: Entity; // CLIENT
const selectedChips: LuaTable<Player, Entity> = new LuaTable(); // SERVER

function hint(msg: string, time: number) {
	notification.AddLegacy(msg, NOTIFY.NOTIFY_HINT, time);
}

function toolEvent(context: any, ply: Player, info: TraceResult) {
	context.data.E2CUser = ply;
	if (info) context.data.E2CRangerInfo = info;
}

if (SERVER) {
	// Add custom e2controller funcs to vex.
	let forceowner = new Cooldown(0.5);
	VNet.addNetString("e2controller_force_selected");
	function getE2ControllerChip(ply: Player) {
		return selectedChips.get(ply);
	}
	function setE2ControllerChip(ply: Player, chip: Entity) {
		// Only when
		if (!IsValid(chip)) return;
			if (chip != selectedChips[ply] && chip.context) {
			selectedChips[ply] = chip;
			let context = chip.context;
			if vex.e2DoesRunOn(context,"e2CSelectedClk") {
				context.data.E2CConnectedPly = ply;
				toolEvent(context,ply);
				chip:Execute();
				context.data.E2CConnectedPly = null;
			}
		}
		// We send the new selected chip to the player, so on the client you don't get that 'you don't have an e2 chip selected!' prompt
		VNet.start("e2controller_force_selected", true);
			net.WriteEntity(chip);
		VNet.send(ply);

		selectedChips[ply] = chip;
	}
else {
	net.Receive("e2controller_force_selected", function() {
		let ent = net.ReadEntity();
		selectedChip = (IsValid(ent) ? ent) : selectedChip;
	});
}

TOOL.LeftClick = function(self: TOOL, trace: TraceResult) {
	let ply = this.GetOwner();
	let plychip = CLIENT && selectedChip || selectedChips[ply];
	if (CLIENT) {
		if (selectedChip) return true;
		if (!IsFirstTimePredicted()) return;

		hint("You don't have an e2 chip selected!", 1.5);
	else if (IsValid(plychip)) {
		let context = plychip.context;
		if vex.e2DoesRunOn(context,"E2CLeftMouseClk") {
			context.data.E2CLeftMouseClk = true
			toolEvent(context,ply,trace);
			plychip.Execute();
			context.data.E2CLeftMouseClk = null;
		}
	}
}

TOOL.Reload = function(self: Tool, trace: TraceResult) {
	let ply = self.GetOwner();
	let plychip = CLIENT && selectedChip || selectedChips[ply]
	if (CLIENT) {
		if selectedChip { return true }
		if not IsFirstTimePredicted() { return }
		hint("You don't have an e2 chip selected!",1.5)
	else if (IsValid(plychip)) {
		let context = plychip.context
		if vex.e2DoesRunOn(context,"E2CReloadClk") {
			context.data.E2CReloadClk = true
			toolEvent(context,ply,trace)
			plychip:Execute()
			context.data.E2CReloadClk = null
		}
	}
}

// If you are looking at an e2 chip, will change e2 chip owner to this.
TOOL.RightClick = function(self: Tool, trace: TraceResult) {
	let ply = self.GetOwner();
	let chip = trace.Entity
	if (IsValid(chip) && chip.GetClass()=="gmod_wire_expression2") {
		// Set the selected chip
		if (CLIENT) {
			if (!IsFirstTimePredicted()) return true;
			hint("Selected E2 Chip", 2);
			selectedChip = chip
		else {
			vex.setE2ControllerChip(ply,chip)
		}
	else {
		let plychip = CLIENT && selectedChip || selectedChips[ply]
		if (IsValid(plychip)) {
			if (CLIENT) return true;
			let context = plychip.context;
			if vex.e2DoesRunOn(context,"E2CRightMouseClk") {
				context.data.E2CRightMouseClk = true;
				toolEvent(context,ply,trace);
				plychip.Execute();
				context.data.E2CRightMouseClk = null;
			}
			return true
		}
	}
}