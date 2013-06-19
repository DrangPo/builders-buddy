// LSL script generated: child.child - base.lslp Tue Jun 18 20:15:04 Eastern Daylight Time 2013

string ALL_CHILDREN = "all";
string ALL_MODULES = "all";
string BASE = "base";
integer BB_API = -11235813;
string MANAGER = "manager";
list values = [];
list vars = [];
integer TRACE = 0;
integer DEBUG = 1;
integer INFO = 2;
integer WARNING = 3;
integer ERROR = 4;
integer DEBUG_LEVEL = TRACE;
string VAR_BASE_ID = "base_id";
string VAR_CHANNEL = "channel";
string VAR_GLOW_ON_IDENTIFY = "glow_on_identify";
string VAR_GLOW_TIMEOUT = "glow_timeout";
string VAR_MAX_X = "max_x";
string VAR_MAX_Y = "max_y";
string VAR_MAX_Z = "max_z";
string VAR_MOVE_ON_REZ = "move_on_rez";
string VAR_REPARENT_DELAY = "reparent_delay";
string VAR_TIMER_DELAY = "timer_delay";
string VAR_YELL_DELAY = "yell_delay";
string VAR_YELL_TIMEOUT = "yell_timeout";
string VAR_MOVE_SAFE = "move_safe";
string VAR_SAY_ON_IDENTIFY = "say_on_identify";
string VAR_CHANNEL_DEFAULT = "-1000001";
string VAR_GLOW_TIMEOUT_DEFAULT = "10";
string VAR_REPARENT_DELAY_DEFAULT = "15";
string VAR_TIMER_DELAY_DEFAULT = "0.5";
string VAR_YELL_DELAY_DEFAULT = "1.0";
string VAR_YELL_TIMEOUT_DEFAULT = "30";
string VAR_MAX_X_DEFAULT = "256.0";
string VAR_MAX_Y_DEFAULT = "256.0";
string VAR_MAX_Z_DEFAULT = "4096.0";
string msg_command;
list msg_details;
string msg_module;
integer parent_channel = 0;
integer parent_handle = 0;
integer listen_channel;
string listen_base;
string listen_command;
list listen_details;
integer listen_password;
string listen_target;

//==============================================================================
// DO NOT EDIT ANYTHING BELOW THIS LINE!!!
//==============================================================================

//==============================================================================
//Base variables
//==============================================================================
integer absolute = FALSE;
integer recorded = FALSE;
vector current_offset;
rotation current_rotation;
rotation dest_rotation;
vector dest_position;
string glowables = "";
integer glow_timeout = 0;
integer is_child = FALSE;
integer need_initial_move = FALSE;
integer need_glow = FALSE;
integer need_move = FALSE;
integer next_yell = 0;
integer need_yell_parent = FALSE;
key parent_key = NULL_KEY;
integer reparent_time = 0;
integer rez_timeout = 0;
integer timer_active = FALSE;
integer moving_single = FALSE;

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
integer is_yes(string var,string default_value){
    return (llToUpper(get(var,default_value)) == "Y");
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
//Child Core Functions
//==============================================================================

////////////////////
integer parse_listen(integer channel,string name,key id,string message){
    (listen_channel = channel);
    list parts = llParseStringKeepNulls(message,["|"],[]);
    if ((llGetListLength(parts) < 3)) return FALSE;
    (listen_base = llList2String(parts,0));
    (listen_target = llList2String(parts,1));
    (listen_command = llList2String(parts,2));
    if ((llGetListLength(parts) > 3)) (listen_details = llList2List(parts,3,(-1)));
    else  (listen_details = []);
    debugl(DEBUG,["child.core.parse_listen()",("listen_base: " + listen_base),("lisen_target: " + listen_target),("listen_command: " + listen_command),("listen_details: " + llDumpList2String(listen_details,"|"))]);
    return TRUE;
}

////////////////////
send_module(string dest_module,string command,list details,integer force){
    send(MANAGER,dest_module,command,details);
}

////////////////////
start_listening(){
    if ((parent_handle != 0)) return;
    if ((parent_channel == 0)) {
        integer config_channel = ((integer)get(VAR_CHANNEL,"-192567"));
        if ((config_channel == 0)) {
            debug(ERROR,"Invalid channel supplied, cannot listen!");
            return;
        }
        (parent_channel = config_channel);
    }
    (parent_handle = llListen(parent_channel,"",NULL_KEY,""));
    send_module(ALL_MODULES,"listen_start",[parent_channel],FALSE);
}

////////////////////
stop_listening(){
    if ((parent_handle != 0)) {
        llListenRemove(parent_handle);
        send_module(ALL_MODULES,"listen_stop",[parent_channel],FALSE);
        (parent_handle = 0);
    }
}

//==============================================================================
// CONFIGURABLE SETTINGS
//==============================================================================
// VAR_BASE_ID:
//   Used to identify this base object to child objects.  Child objects will
//   only respond to base objects that match the name set in their child script.
//==============================================================================
// VAR_CHANNEL
//   General-use channel to listen on.  Newly-created child objects will attempt
//   to find the base object on this channel.  If changing this value, make
//   sure it is a negative number.
//==============================================================================
// VAR_GLOW_ON_IDENTIFY:
//   Will make ths object glow if the user selects "Identify" in the Creator's
//   menu.  Set to "Y" or "N". (Note: as a safety precaution, linked objects 
//   that already have a glow will not be changed.)
//==============================================================================
// VAR_GLOW_TIMEOUT:
//   How long, in seconds, to active the glow, if VAR_GLOW_ON_IDENTIFY is set
//   to "Y".
//==============================================================================
// VAR_MAX_X:
//   The maximum X position that this object will be permitted to move to.
//==============================================================================
// VAR_MAX_Y:
//   The maximum Y position that this object will be permitted to move to.
//==============================================================================
// VAR_MAX_Z:
//   The maximum Z position that this object will be permitted to move to.
//==============================================================================
// VAR_MOVE_ON_REZ:
//   Will attempt to move into position as soon as the child object is rezzed,
//   without waiting for link to parent to complete.  This assumes that the
//   on-rezzed position and rotation match those of the parent object.  Must be
//   set to "Y" or "N".
//==============================================================================
// VAR_MOVE_SAFE:
//   If set to "Y", child object will attempt to move using the safe method,
//   which tries to detect if the object gets stuck on the ground.  This method
//   is more reliable, but slower.  If set to "N", will use the faster method
//   to set the position, but does not perform the check.
//==============================================================================
// VAR_REPARENT_DELAY:
//   How long to wait, in seconds, before assuming the parent object no longer
//   exists if it is not heard.  Child object will attempt to find a new parent
//   to relink to after this time.
//==============================================================================
// VAR_SAY_ON_IDENTIFY:
//   Will make ths object announce its name and positio if the user selects 
//   "Identify" in the Creator's menu.  Set to "Y" or "N".
//==============================================================================
// VAR_TIMER_DELAY:
//   Amount of time, in floating seconds, between ticks of the timer.  Lower
//   numbers will make things more responsive, but causes higher region lag.
//==============================================================================
// VAR_YELL_DELAY:
//   How frequently, in seconds, to announce to the region that this child
//   object is looking for a parent to link to.
//==============================================================================
// VAR_YELL_TIMEOUT:
//   Amount of time, in seconds, before child script assumes no parent is going
//   to respond.  If the child has been rezzed as a part of a "Build" process,
//   will self-delete at this time.  If a non-rezzed objected, child will fall
//   back to the channel in VAR_CHANNEL and seek out a parent there.
//==============================================================================
initialize(){
    set(VAR_BASE_ID,"bb3_base");
    set(VAR_CHANNEL,"-192567");
    set(VAR_GLOW_ON_IDENTIFY,"Y");
    set(VAR_GLOW_TIMEOUT,"10");
    set(VAR_MAX_X,"256.0");
    set(VAR_MAX_Y,"256.0");
    set(VAR_MAX_Z,"4096.0");
    set(VAR_MOVE_ON_REZ,"Y");
    set(VAR_MOVE_SAFE,"N");
    set(VAR_REPARENT_DELAY,"15.0");
    set(VAR_SAY_ON_IDENTIFY,"N");
    set(VAR_TIMER_DELAY,"0.25");
    set(VAR_YELL_DELAY,"3.0");
    set(VAR_YELL_TIMEOUT,"30.0");
}

//==============================================================================
//Base Functions
//==============================================================================

////////////////////
build_glow_snapshot(){
    debug(DEBUG,"Building glow snapshot");
    (glowables = "");
    integer num_links = llGetObjectPrimCount(llGetKey());
    integer link = 0;
    if ((num_links == 1)) {
        if ((!has_glow(0))) (glowables = "00");
    }
    else  {
        for ((link = 1); (link <= num_links); (link++)) {
            if ((!has_glow(link))) {
                (glowables += int_to_hex(link));
            }
        }
    }
    (need_glow = FALSE);
    check_timer();
    debug(TRACE,("Glowables: " + glowables));
}

////////////////////
check_parent(){
    if ((parent_key == NULL_KEY)) return;
    integer lost_parent = FALSE;
    if ((llGetUnixTime() > reparent_time)) {
        (lost_parent = TRUE);
    }
    else  {
        if ((llGetListLength(llGetObjectDetails(parent_key,[OBJECT_OWNER])) == 0)) (lost_parent = TRUE);
    }
    if (lost_parent) {
        debug(TRACE,"Parent link lost");
        send_module(ALL_MODULES,"lost_parent",[parent_key],FALSE);
        (parent_key = NULL_KEY);
        (parent_channel = ((integer)get(VAR_CHANNEL,VAR_CHANNEL_DEFAULT)));
        set_yell_parent();
        check_timer();
    }
}

////////////////////
check_timer(){
    integer need_timer = FALSE;
    if (need_glow) (need_timer = TRUE);
    if ((glow_timeout != 0)) (need_timer = TRUE);
    if (need_move) (need_timer = TRUE);
    if (need_yell_parent) (need_timer = TRUE);
    if ((next_yell != 0)) (need_timer = TRUE);
    if ((!timer_active)) {
        if (need_timer) {
            llSetTimerEvent(((float)get(VAR_TIMER_DELAY,VAR_TIMER_DELAY_DEFAULT)));
            (timer_active = TRUE);
        }
    }
    else  {
        if ((!need_timer)) {
            llSetTimerEvent(0.0);
            (timer_active = FALSE);
        }
    }
}

////////////////////
integer from_parent(key source_id,string source_base_id,string child_id,integer password){
    if ((parent_key != NULL_KEY)) {
        if ((parent_key == source_id)) (reparent_time = (llGetUnixTime() + ((integer)get(VAR_REPARENT_DELAY,VAR_REPARENT_DELAY_DEFAULT))));
    }
    check_parent();
    if ((parent_key == NULL_KEY)) {
        string base_id = get(VAR_BASE_ID,"");
        if ((base_id == "")) {
            debug(TRACE,"Potential parent rejected, no base ID in child script");
            return FALSE;
        }
        if ((source_base_id != base_id)) {
            debugl(TRACE,["Potential parent rejected, base ID mismatch",("child base id: " + base_id),("source base: " + source_base_id)]);
            return FALSE;
        }
        if ((llGetOwnerKey(source_id) != llGetOwner())) {
            debug(TRACE,"Potential parent rejected, owner mismatch");
            return FALSE;
        }
        (parent_key = source_id);
        (reparent_time = (llGetUnixTime() + ((integer)get(VAR_REPARENT_DELAY,VAR_REPARENT_DELAY_DEFAULT))));
        send_module(ALL_MODULES,"have_parent",[parent_key],FALSE);
        debug(INFO,(("Base object " + ((string)source_id)) + " found and locked on."));
    }
    if ((source_id == parent_key)) {
        (reparent_time = (llGetUnixTime() + ((integer)get(VAR_REPARENT_DELAY,VAR_REPARENT_DELAY_DEFAULT))));
        if ((child_id == ALL_CHILDREN)) return TRUE;
        if ((((key)child_id) == llGetKey())) return TRUE;
    }
    return FALSE;
}

////////////////////
got_parent_message(){
    if ((listen_command == "ping")) {
        send_parent("pong",[]);
        return;
    }
    if ((listen_command == "record")) {
        vector base_pos = ((vector)llList2String(listen_details,0));
        rotation base_rotation = ((rotation)llList2String(listen_details,1));
        (absolute = ((integer)llList2Integer(listen_details,2)));
        if (absolute) {
            (current_rotation = llGetRot());
            (current_offset = llGetPos());
        }
        else  {
            (current_offset = ((llGetPos() - base_pos) / base_rotation));
            (current_rotation = (llGetRot() / base_rotation));
        }
        (recorded = TRUE);
        send_module(ALL_MODULES,"record",[current_offset,current_rotation,absolute,TRUE],FALSE);
        llOwnerSay("Recorded position.");
        return;
    }
    if ((listen_command == "record_using")) {
        (current_offset = ((vector)llList2String(listen_details,0)));
        (current_rotation = ((rotation)llList2String(listen_details,1)));
        (absolute = llList2Integer(listen_details,2));
        (recorded = TRUE);
        send_module(ALL_MODULES,"record",[current_offset,current_rotation,absolute],FALSE);
        return;
    }
    if ((listen_command == "clear")) {
        send_module(ALL_MODULES,"clear",[],FALSE);
        (recorded = FALSE);
        return;
    }
    if ((listen_command == "clear_scripts")) {
        send_module(ALL_MODULES,"clear_scripts",[],FALSE);
        llRemoveInventory(llGetScriptName());
        return;
    }
    if ((listen_command == "movesingle")) {
        if ((!moving_single)) {
            (moving_single = TRUE);
            pre_move_relative(((vector)llList2String(listen_details,0)),((rotation)llList2String(listen_details,1)));
            move();
            send_module(ALL_MODULES,"move",[dest_position,dest_rotation,TRUE],FALSE);
        }
        return;
    }
    if ((listen_command == "move")) {
        (moving_single = FALSE);
        pre_move_relative(((vector)llList2String(listen_details,0)),((rotation)llList2String(listen_details,1)));
        return;
    }
    if ((listen_command == "move_absolute")) {
        pre_move(((vector)llList2String(listen_details,0)),((rotation)llList2String(listen_details,1)));
        return;
    }
    if ((listen_command == "clean")) {
        send_module(ALL_MODULES,"clean",[],FALSE);
        llDie();
    }
    if ((listen_command == "mod_say")) {
        send_module(ALL_MODULES,"mod_say",listen_details,FALSE);
        return;
    }
    if ((listen_command == "identify")) {
        if (is_yes(VAR_SAY_ON_IDENTIFY,"Y")) {
            llOwnerSay(((("Builder's Buddy, child: \"" + llGetScriptName()) + "\" at location: ") + ((string)llGetPos())));
        }
        if (is_yes(VAR_GLOW_ON_IDENTIFY,"N")) {
            if (need_glow) build_glow_snapshot();
            set_glow(1.0);
            (glow_timeout = (llGetUnixTime() + ((integer)get(VAR_GLOW_TIMEOUT,VAR_GLOW_TIMEOUT_DEFAULT))));
            check_timer();
        }
        return;
    }
    if ((listen_command == "base_prim")) {
        debug(INFO,"Parent configuration received");
        string channel = llList2String(listen_details,0);
        if (((channel != "") && (channel != ""))) {
            debug(DEBUG,("Listening to parent object on channel " + channel));
            stop_listening();
            (parent_channel = ((integer)channel));
            start_listening();
        }
        if ((recorded && need_initial_move)) {
            pre_move_relative(((vector)llList2String(listen_details,1)),((rotation)llList2String(listen_details,2)));
            (need_initial_move = FALSE);
        }
        (need_yell_parent = FALSE);
        (next_yell = 0);
        check_timer();
    }
}

////////////////////
integer has_glow(integer link){
    integer num_faces = llGetLinkNumberOfSides(link);
    integer face = 0;
    list params = [];
    for ((face = 0); (face < num_faces); (face++)) {
        (params += [PRIM_GLOW,face]);
    }
    list glows = llGetLinkPrimitiveParams(link,params);
    integer num_glows = llGetListLength(glows);
    for ((face = 0); (face < num_faces); (face++)) {
        float glow_value = llList2Float(glows,face);
        if ((glow_value != 0.0)) {
            return TRUE;
        }
    }
    return FALSE;
}

////////////////////
string int_to_hex(integer int_value){
    string hex;
    do  {
        (hex = (llGetSubString("0123456789ABCDEF",(int_value & 15),(int_value & 15)) + hex));
    }
    while ((int_value = ((int_value >> 4) & 268435455)));
    if ((llStringLength(hex) == 1)) (hex = ("0" + hex));
    return hex;
}


////////////////////
hop(vector destination,rotation rot){
    integer hops = llAbs(llCeil((llVecDist(llGetPos(),destination) / 10.0)));
    integer x;
    while ((hops > 0)) {
        list params = [];
        integer hopBlock = hops;
        if ((hopBlock > 50)) (hopBlock = 50);
        for ((x = 0); (x < hopBlock); (x++)) {
            (params += [PRIM_POSITION,destination]);
        }
        (params += [PRIM_ROTATION,rot]);
        llSetPrimitiveParams(params);
        (hops -= hopBlock);
    }
}

////////////////////
move(){
    if (is_yes(VAR_MOVE_SAFE,"N")) {
        move_safe();
    }
    else  {
        llSetRegionPos(dest_position);
        llSetRot(dest_rotation);
    }
    send_module(ALL_MODULES,"at_destination",[dest_position,dest_rotation],FALSE);
    (need_move = FALSE);
    check_timer();
}

////////////////////
move_safe(){
    integer i = 0;
    integer atDestination = FALSE;
    vector vLastPos = ZERO_VECTOR;
    do  {
        if ((llGetPos() == vLastPos)) {
            hop((llGetPos() + <0.0,0.0,500.0>),dest_rotation);
        }
        hop(dest_position,dest_rotation);
        (vLastPos = llGetPos());
        (i++);
    }
    while (((i < 5) && (llGetPos() != dest_position)));
    llSetRot(dest_rotation);
}

////////////////////
pre_move(vector new_position,rotation new_rotation){
    float max_x = ((float)get(VAR_MAX_X,VAR_MAX_X_DEFAULT));
    if ((new_position.x < 0.0)) (new_position.x = 0.0);
    if ((new_position.x >= max_x)) (new_position.x = max_x);
    float max_y = ((float)get(VAR_MAX_Y,VAR_MAX_Y_DEFAULT));
    if ((new_position.y < 0.0)) (new_position.y = 0.0);
    if ((new_position.y > max_y)) (new_position.y = max_y);
    float max_z = ((float)get(VAR_MAX_Z,VAR_MAX_Z_DEFAULT));
    if ((new_position.z > max_z)) (new_position.z = max_z);
    (dest_position = new_position);
    (dest_rotation = new_rotation);
    send_module(ALL_MODULES,"move",[dest_position,dest_rotation],FALSE);
    if ((!need_move)) {
        llResetTime();
        (need_move = TRUE);
        check_timer();
    }
    return;
}

////////////////////
pre_move_relative(vector new_position,rotation new_rotation){
    if ((!recorded)) return;
    vector new_dest_position;
    rotation new_dest_rotation;
    if ((!absolute)) {
        (new_dest_position = ((current_offset * new_rotation) + new_position));
        (new_dest_rotation = (current_rotation * new_rotation));
    }
    else  {
        (new_dest_position = current_offset);
        (new_dest_rotation = current_rotation);
    }
    pre_move(new_dest_position,new_dest_rotation);
}

////////////////////
send_parent(string command,list options){
    if ((parent_key == NULL_KEY)) {
        debugl(DEBUG,["child - base.send_parent()",("channel: " + get(VAR_CHANNEL,VAR_CHANNEL_DEFAULT))]);
        llRegionSay(parent_channel,llDumpList2String(([BASE,command] + options),"|"));
    }
    else  {
        debugl(DEBUG,["child - base.send_parent()",("channel: " + ((string)parent_key))]);
        llRegionSayTo(parent_key,parent_channel,llDumpList2String(([parent_key,command] + options),"|"));
    }
}

////////////////////
set_glow(float glow){
    debug(DEBUG,("Setting glow to " + ((string)glow)));
    integer glowables_length = llStringLength(glowables);
    integer link;
    for ((link = 0); (link < glowables_length); (link += 2)) {
        string link_hex = ("0x" + llGetSubString(glowables,link,(link + 1)));
        integer the_link = ((integer)link_hex);
        llSetLinkPrimitiveParamsFast(the_link,[PRIM_GLOW,ALL_SIDES,glow]);
    }
    (glow_timeout = 0);
}

////////////////////
yell_parent(){
    debug(DEBUG,"Yelling for a parent");
    (next_yell = (llGetUnixTime() + ((integer)get(VAR_YELL_DELAY,VAR_YELL_DELAY_DEFAULT))));
    send_module(ALL_MODULES,"ready_to_pos",[],FALSE);
    send_parent("ready_to_pos",[]);
}

////////////////////
set_yell_parent(){
    (need_yell_parent = TRUE);
    (next_yell = (llGetUnixTime() + ((integer)get(VAR_YELL_DELAY,VAR_YELL_DELAY_DEFAULT))));
    check_timer();
}

////////////////////
////////////////////
////////////////////
default {

	////////////////////
	state_entry() {
        debug(DEBUG,"====================");
        debug(DEBUG,"   SCRIPT STARTED");
        debug(DEBUG,"====================");
        initialize();
        (need_move = FALSE);
        start_listening();
        send_module(ALL_MODULES,"reset",[],TRUE);
        (need_glow = TRUE);
        set_yell_parent();
        check_timer();
        llOwnerSay(("Memory free: " + ((string)llGetFreeMemory())));
    }


	////////////////////
	link_message(integer sender_num,integer number,string message,key id) {
        if (parse([MANAGER,ALL_MODULES],number,message,id)) {
            return;
        }
    }


	////////////////////
	listen(integer channel,string name,key id,string message) {
        debugl(TRACE,["Heard:",("channel: " + ((string)channel)),("name: " + name),("id: " + ((string)id)),("message: " + message)]);
        if (parse_listen(channel,name,id,message)) {
            if (from_parent(id,listen_base,listen_target,listen_password)) {
                got_parent_message();
                return;
            }
        }
    }

	
	////////////////////
	on_rez(integer start_param) {
        stop_listening();
        if ((start_param != 0)) {
            (parent_channel = start_param);
            (is_child = TRUE);
            (need_initial_move = TRUE);
            (rez_timeout = (llGetUnixTime() + ((integer)get(VAR_YELL_TIMEOUT,VAR_YELL_TIMEOUT_DEFAULT))));
            send_module(ALL_MODULES,"rezzed",[start_param],FALSE);
            if (is_yes(VAR_MOVE_ON_REZ,"N")) {
                (moving_single = FALSE);
                pre_move_relative(llGetPos(),llGetRot());
            }
        }
        else  {
            (is_child = FALSE);
        }
        (parent_key = NULL_KEY);
        set_yell_parent();
        check_timer();
        start_listening();
    }

    
    ////////////////////
	timer() {
        integer now = llGetUnixTime();
        if (need_yell_parent) {
            if ((rez_timeout != 0)) {
                if ((now > rez_timeout)) {
                    send_module(ALL_MODULES,"no_parent",[],FALSE);
                    if (is_child) llDie();
                    integer default_channel = ((integer)get(VAR_CHANNEL,VAR_CHANNEL_DEFAULT));
                    if ((default_channel != parent_channel)) {
                        debug(DEBUG,"Reverting to default channel");
                        stop_listening();
                        (parent_channel = default_channel);
                        start_listening();
                    }
                }
            }
            if ((now > next_yell)) {
                yell_parent();
            }
        }
        if (need_move) {
            move();
            if (moving_single) {
                send_parent("at_destination",[]);
            }
        }
        if (need_glow) build_glow_snapshot();
        if ((glow_timeout != 0)) {
            if ((now > glow_timeout)) {
                set_glow(0.0);
                (glow_timeout = 0);
            }
        }
        check_timer();
        return;
    }

    
    ////////////////////
    changed(integer change) {
        if ((glow_timeout == 0)) {
            (need_glow = TRUE);
            check_timer();
        }
    }
}
