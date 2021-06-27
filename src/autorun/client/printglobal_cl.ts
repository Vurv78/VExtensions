
// These are replicated from the server, so you cannot edit them but you can access their values.
CreateConVar("vex_printglobal_charmax_sv", "500", FCVAR.FCVAR_REPLICATED, "The amount of chars that can be sent with the e2function printGlobal()", 0,2000);
CreateConVar("vex_printglobal_argmax_sv", "100", FCVAR.FCVAR_REPLICATED, "The amount of arguments that can be sent with the e2function printGlobal()", 0, 255);
CreateConVar("vex_printglobal_enable_cl","1", FCVAR.FCVAR_ARCHIVE + FCVAR.FCVAR_USERINFO, "Allows players to print messages to your chat with expression2", 0, 1);

function printf(...args: any[]) {
	print( string.format(args) );
}

function warnClient(sender: Player) {
	printf("%s is printing to your chat with printGlobal. To disable this, set vex_printglobal_enable_cl to 0", IsValid(sender) ? sender.GetName() : "Unknown Player" );
}


net.Receive("vex_printglobal", function() {
	// We don't check the convar here, the server does that.
	let sender = net.ReadEntity();
	if (sender !== LocalPlayer()) warnClient(sender);

	let result = {}
	for (let I = 1; I < net.ReadUInt(5); I+=2) {
		result[I] = Color( net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8) );
		result[I+1] = net.ReadString();
	end
	chat.AddText( unpack( result ) )
});