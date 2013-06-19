// LSL script generated: child.modules.child - description storage.lslp Tue Jun 18 20:15:04 Eastern Daylight Time 2013

string ALL_MODULES = "all";
integer BB_API = -11235813;
string MANAGER = "manager";
string TYPE_CHILD = "C";
string TYPE_PARENT = "P";
integer TRACE = 0;
integer DEBUG = 1;
integer INFO = 2;
integer WARNING = 3;
integer ERROR = 4;
integer DEBUG_LEVEL = TRACE;
list values = [];
list vars = [];
string MENU_TYPE_ADMIN = "A";
string MENU_TYPE_EVERYONE = "E";
string MENU_TYPE_NONE = "X";
string VAR_MOD_EVENTS = "mod_events";
string VAR_MOD_MENU_DESC = "mod_menu_desc";
string VAR_MOD_MENU_TYPE = "mod_menu_type";
string VAR_MOD_NAME = "mod_name";
string VAR_MOD_TYPE = "mod_type";
string msg_command;
list msg_details;
string msg_module;
string module = "";
////////////////////
debug(integer level,string text){
    if ((level >= DEBUG_LEVEL)) llOwnerSay(((((("[" + llGetScriptName()) + "]") + get_level_text(level)) + " ") + text));
}

////////////////////
debugl(integer level,list lines){
    debug(level,llDumpList2String(lines,"\n\t"));
}

string get_level_text(integer level){
    if ((level == TRACE)) return "[trace]";
    if ((level == DEBUG)) return "[debug]";
    if ((level == INFO)) return "[info]";
    if ((level == WARNING)) return "[warning]";
    if ((level == ERROR)) return "[error]";
    return "";
}

//==============================================================================
//Storage Functions
//==============================================================================

////////////////////
string get(string name,string default_value){
    integer iFound = llListFindList(vars,[name]);
    if ((iFound != (-1))) return llList2String(values,iFound);
    return default_value;
}

////////////////////
list get_list(string varName,list default_list){
    integer iFound = llListFindList(vars,[varName]);
    if ((iFound != (-1))) {
        return llParseStringKeepNulls(llList2String(values,iFound),["|"],[""]);
    }
    return default_list;
}

////////////////////
set(string name,string value){
    (name = llToLower(name));
    integer iFound = llListFindList(vars,[name]);
    if ((iFound != (-1))) {
        (values = llListReplaceList(values,[value],iFound,iFound));
    }
    else  {
        (vars += name);
        (values += value);
    }
}

////////////////////
set_list(string name,list values){
    set(name,llDumpList2String(values,"|"));
}

//==============================================================================
//Communication functions
//==============================================================================

// message: <source>|<target>|<command>
// id: <details...>
////////////////////
integer parse(list targets,integer number,string message,string id){
    if ((number != BB_API)) return FALSE;
    list parts = llParseStringKeepNulls(((string)id),["|"],[]);
    if ((llGetListLength(parts) != 3)) return FALSE;
    integer num_targets = llGetListLength(targets);
    integer i;
    string target = llList2String(parts,1);
    for ((i = 0); (i < num_targets); (i++)) {
        if ((llList2String(targets,i) == target)) {
            (msg_module = llList2String(parts,0));
            (msg_command = llList2String(parts,2));
            (msg_details = llParseStringKeepNulls(message,["|"],[]));
            debugl(TRACE,["common.comm.parse():",msg_module,msg_command,message]);
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
send(string source,string dest,string command,list details){
    debugl(TRACE,["common.common.send():",("dest: " + dest),("command: " + command),("details: " + llDumpList2String(details,"|"))]);
    llMessageLinked(LINK_THIS,BB_API,llDumpList2String(details,"|"),llDumpList2String([source,dest,command],"|"));
}

//==============================================================================
// Utility Functions
//==============================================================================

////////////////////
string get_short_name(string longName){
    (longName = llSHA1String(longName));
    string shortName;
    integer ptr = 0;
    integer strLength = llStringLength(longName);
    string char;
    for ((ptr = 0); (ptr < strLength); (ptr += 2)) {
        integer ord = ((integer)("0x" + llGetSubString(longName,ptr,(ptr + 1))));
        if ((ord <= 0)) {
            (char = "");
        }
        else  if ((ord < 128)) {
            (char = llUnescapeURL(get_url_code(ord)));
        }
        else  if ((ord < 2048)) {
            (char = llUnescapeURL((get_url_code((((ord >> 6) & 31) | 192)) + get_url_code(((ord & 63) | 128)))));
        }
        else  if ((ord < 65536)) {
            (char = llUnescapeURL(((get_url_code((((ord >> 12) & 15) | 224)) + get_url_code((((ord >> 6) & 63) | 128))) + get_url_code(((ord & 63) | 128)))));
        }
        else  {
            (char = llUnescapeURL((((get_url_code((((ord >> 18) & 15) | 240)) + get_url_code((((ord >> 12) & 63) | 128))) + get_url_code((((ord >> 6) & 63) | 128))) + get_url_code(((ord & 63) | 128)))));
        }
        (shortName += char);
    }
    return shortName;
}

////////////////////
string get_url_code(integer b){
    string hexd = "0123456789ABCDEF";
    return (("%" + llGetSubString(hexd,(b >> 4),(b >> 4))) + llGetSubString(hexd,(b & 15),(b & 15)));
}

//==============================================================================
//Manager Core Functions
//==============================================================================

////////////////////
check_name(){
    (module = get_short_name(llGetScriptName()));
    (module = llDumpList2String(llParseStringKeepNulls(module,["|"],[]),""));
    debugl(TRACE,["mod_check_name():",((((("Module: " + llGetScriptName()) + ", short name: ") + module) + ", length: ") + ((string)llStringLength(module)))]);
}

////////////////////
integer handle_message(){
    debugl(TRACE,(["module.core.handle_message()",msg_module,msg_command] + msg_details));
    if ((msg_module == MANAGER)) {
        if ((msg_command == "reset")) {
            llResetScript();
            return TRUE;
        }
        if ((msg_command == "register")) {
            debug(DEBUG,"Registration received");
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
register(string module_type,string menu_type,list events,string label,string desc){
    (menu_type = llToUpper(menu_type));
    if ((((menu_type != MENU_TYPE_ADMIN) && (menu_type != MENU_TYPE_EVERYONE)) && (menu_type != MENU_TYPE_NONE))) {
        llOwnerSay("mod_register: Invalid menu type specified, please check script.");
        return;
    }
    if (((module_type != TYPE_PARENT) && (module_type != TYPE_CHILD))) {
        llOwnerSay("mod_register: Invalid module type specified, please check script.");
        return;
    }
    list details = [llGetScriptName(),module_type,menu_type,llDumpList2String(events,","),label,desc];
    send_manager("register",details);
}

////////////////////
register_quick(){
    string modType = get(VAR_MOD_TYPE,TYPE_CHILD);
    string modName = get(VAR_MOD_NAME,"SET_MOD_NAME");
    string menuDesc = get(VAR_MOD_MENU_DESC,"(No description)");
    string menuType = get(VAR_MOD_MENU_TYPE,MENU_TYPE_NONE);
    list modEvents = get_list(VAR_MOD_EVENTS,[]);
    register(modType,menuType,modEvents,modName,menuDesc);
}

////////////////////
send_manager(string command,list details){
    send(module,MANAGER,command,details);
}


////////////////////
mod_changed(integer change){
    if ((change & CHANGED_INVENTORY)) check_name();
}

////////////////////
mod_state_entry(){
    debug(DEBUG,"====================");
    debug(DEBUG,"   SCRIPT STARTED   ");
    debug(DEBUG,"====================");
    check_name();
    register_quick();
}

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
// mod_type:
//   Indicates if this module should link to the parent or component scripts.  
//   Set to one of:
//     CORE_TYPE_PARENT - Module intended for use in the parent prim
//     CORE_TYPE_CHILD - Module intended for use in the child prims;
//==============================================================================
// menu_type:
//   The type of button to be added to the menu.  Set to one of:
//   MOD_MENU_TYPE_ADMIN - Button is seen only by administrators/creators
//   MOD_MENU_TYPE_EVERYONE - Button is seen by everyone
//   MOD_MENU_TYPE_NONE - No button will be shown.     
//==============================================================================
// mod_name:
//   The name of the module.  If menu_type is set to MOD_MENU_TYPE_ADMIN
//   or MOD_MENU_TYPE_EVERYONE, this will be used as the label on the button.    
//==============================================================================
// mod_menu_desc:
//   Description of the module. Will be included in the text of the menu when
//   the module's button is display.    
//==============================================================================
// mod_events:
//   Events that this module wishes to review and possibly cancel.  These can
//   only be events that are explicitly available as cancellable in the base or
//   component script.  This should be set as a list using setList();
//==============================================================================
initialize(){
    set("mod_type",TYPE_CHILD);
    set("mod_name","Description Storage");
    set("mod_menu_type",MENU_TYPE_NONE);
    set("mod_menu_desc","Store object's location in Description");
    set_list("mod_events",["record","forget"]);
}

clean_description(){
    string desc = llGetObjectDesc();
    integer start = llSubStringIndex(desc,"BB3");
    if ((start != (-1))) {
        string block = llGetSubString(desc,(start + 3),(-1));
        integer iEnd = llSubStringIndex(block,"3BB");
        if ((iEnd != (-1))) {
            string new_desc = "";
            if ((start >= 3)) (new_desc = llGetSubString(desc,0,(start - 1)));
            string tail = llGetSubString(block,iEnd,(-1));
            if ((tail != "3BB")) (new_desc += llGetSubString(tail,3,(-1)));
            llSetObjectDesc(new_desc);
        }
    }
}

//floatToString and stringToFloat (suif and fuis) courtesy of Strife Onizuka
//float union to base64ed integer
string floatToString(float a){
    if (a) {
        integer b = ((a < 0) << 31);
        if (((a = llFabs(a)) < 2.3509887016445748e-38)) {
            (b = (b | ((integer)(a / 1.4012984643248169e-45))));
        }
        else  {
            integer c = llFloor((llLog(a) / 0.6931471805599453));
            (b = ((8388607 & ((integer)(a * (16777216 >> b)))) | ((((c + 126) + (b = (((integer)a) - (3 <= (a /= ((float)("0x1p" + ((string)(c -= (c == 128)))))))))) << 23) | b)));
        }
        return llGetSubString(llIntegerToBase64(b),0,5);
    }
    if ((((string)a) == ((string)0.0))) return "AAAAAA";
    return "gAAAAA";
}

got_message(){
    debugl(TRACE,["creator.got_message()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "record")) {
        vector vOffset = ((vector)llList2String(msg_details,0));
        rotation rRotation = ((rotation)llList2String(msg_details,1));
        integer bAbsolute = llList2Integer(msg_details,2);
        integer from_base = llList2Integer(msg_details,3);
        if (from_base) {
            debugl(DEBUG,["Recording to object description:",("offset: " + ((string)vOffset)),("rotation: " + ((string)rRotation)),("absolute: " + ((string)bAbsolute))]);
            saveToDescription(vOffset,rRotation,bAbsolute);
        }
        return;
    }
    if ((msg_command == "clear")) {
        clean_description();
        return;
    }
    if ((msg_command == "clear_scripts")) {
        clean_description();
        llRemoveInventory(llGetScriptName());
        return;
    }
    if ((msg_command == "register")) {
        load_description();
        return;
    }
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
// This is called when the module has received a cancellable request.  This
// must return TRUE to cancel the event, or FALSE to allow it to continue.
// Unless your module has a specific need to stop the event from happening, this
// should normally return FALSE.
//
//Only cancellable events listed in mod_events will be seen here.
//==============================================================================
integer got_request(){
    debugl(TRACE,["creator.got_request()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    return FALSE;
}

load_description(){
    string desc = llGetObjectDesc();
    vector vOffset;
    rotation rRotation;
    integer bAbsolute = FALSE;
    integer start = llSubStringIndex(desc,"BB3");
    if ((start != (-1))) {
        string block = llGetSubString(desc,(start + 3),(-1));
        integer iEnd = llSubStringIndex(block,"3BB");
        if ((iEnd != (-1))) {
            debug(DEBUG,"Retrieving recorded position from description");
            string data = llGetSubString(block,0,(iEnd - 1));
            list lData = llParseStringKeepNulls(data,[","],[]);
            (rRotation = <stringToFloat(llList2String(lData,0)),stringToFloat(llList2String(lData,1)),stringToFloat(llList2String(lData,2)),stringToFloat(llList2String(lData,3))>);
            (vOffset = <stringToFloat(llList2String(lData,4)),stringToFloat(llList2String(lData,5)),stringToFloat(llList2String(lData,6))>);
            (bAbsolute = llList2Integer(lData,7));
            debugl(TRACE,["Location Info:",("Position: " + ((string)vOffset)),("Rotation: " + ((string)rRotation)),("Absolute: " + ((string)bAbsolute))]);
            send_manager("record_using",[vOffset,rRotation,bAbsolute]);
            return;
        }
    }
    debug(DEBUG,"No description data found.");
}

//==============================================================================
//BUILDER'S BUDDY MODULE CODE - DO NOT REMOVE
//==============================================================================
parse_message(){
    debugl(TRACE,["parse_message()",("msg_command: " + msg_command),("msg_details: " + llDumpList2String(msg_details,"|"))]);
    if ((msg_command == "request_event")) {
        (msg_command = llList2String(msg_details,0));
        (msg_details = llList2List(msg_details,1,(-1)));
        integer cancelled = got_request();
        send_manager("request_ack",[msg_command,cancelled]);
    }
    else  {
        got_message();
    }
}


saveToDescription(vector vOffset,rotation rRotation,integer bAbsolute){
    clean_description();
    string text = llDumpList2String([floatToString(rRotation.x),floatToString(rRotation.y),floatToString(rRotation.z),floatToString(rRotation.s),floatToString(vOffset.x),floatToString(vOffset.y),floatToString(vOffset.z),bAbsolute],",");
    string oldDesc = llGetObjectDesc();
    string newDesc = (((oldDesc + "BB3") + text) + "3BB");
    llSetObjectDesc(newDesc);
    if ((llGetObjectDesc() != newDesc)) {
        llOwnerSay("Could not save recording in description, was truncated!");
        llSetObjectDesc(oldDesc);
    }
}

float stringToFloat(string b){
    integer a = llBase64ToInteger(b);
    return ((((float)("0x1p" + ((string)((a | (!a)) - 150)))) * (((!(!(a = (255 & (a >> 23))))) << 23) | (a & 8388607))) * (1 | (a >> 31)));
}


default {

	state_entry() {
        initialize();
        mod_state_entry();
    }

	
	changed(integer change) {
        mod_changed(change);
    }


	link_message(integer sender_num,integer number,string message,key id) {
        if (parse([module,ALL_MODULES],number,message,id)) {
            if (handle_message()) return;
            parse_message();
        }
    }
}
