//#define DEBUG_SYNCHRONOUS
//#define DEBUG_MODE_FULL
#include "script_component.hpp"
LOG("START placementSelection");
if (!isNil "placementDone") then {
    LOG("petros is dead");
	Slowhand allowDamage false;
	(localize "STR_HINTS_HQPLACE_DEATH_TITLE") hintC localize "STR_HINTS_HQPLACE_DEATH";
} else {
	diag_log "Antistasi: New Game selected";
	(localize "STR_HINTS_HQPLACE_START_TITLE") hintC [localize "STR_HINTS_HQPLACE_START_1",localize "STR_HINTS_HQPLACE_START_2",localize "STR_HINTS_HQPLACE_START_3"];
};

[mrkAAF,false] params ["_markers","_enemiesNearby"];
private ["_nearestZone","_position","_oldUnit","_spawnPos","_direction"];

if (isNil "placementDone") then {
	_markers = _markers - controlsX;
	openMap true;
} else {
	openMap [true,true];
};

while {true} do {
	clickPosition = [];
	onMapSingleClick "clickPosition = _pos;";
    LOG("waiting for click");
	waitUntil {sleep 1; (count clickPosition > 0) OR !visiblemap};
	onMapSingleClick "";
    LOG_1("Click is done: %1", clickPosition);
	if !(visiblemap) exitWith {};
	_position = clickPosition;
	_nearestZone = [_markers,_position] call BIS_fnc_nearestPosition;

	private _clickNearZone = getMarkerPos _nearestZone distance _position < 1000;
	private _isWater = surfaceIsWater _position;
	if (_clickNearZone) then {
        LOG("click near zone");
	    hint localize "STR_HINTS_HQPLACE_ZONES"
	};
	if (_isWater) then {
        LOG("click on water");
	    hint localize "STR_HINTS_HQPLACE_WATER"
	};

	private _enemiesNearby = false;
	if (!isNil "placementDone") then {
		{
			if ((side _x == side_green) OR (side _x == side_red)) then {
				if (_x distance _position < 1000) then {_enemiesNearby = true};
			};
		} forEach allUnits;
	};
	if (_enemiesNearby) then {hint localize "STR_HINTS_HQPLACE_ENEMIES"};
	if (!_clickNearZone AND !_isWater AND !_enemiesNearby) exitWith {
	    LOG("Click position is good to deploy HQ");
	};
};

if (visiblemap) then {
	if (isNil "placementDone") then {
		{
			if (getMarkerPos _x distance _position < 1000) then {
				mrkAAF = mrkAAF - [_x];
				mrkFIA = mrkFIA + [_x];
			};
		} forEach controlsX;
		publicVariable "mrkAAF";
		publicVariable "mrkFIA";
		petros setPos _position;
	} else {
        LOG("start resetting flag");
		AS_flag_resetDone = false;
		[_position] remoteExec ["AS_fnc_resetHQ",2];
		waitUntil {AS_flag_resetDone};
        LOG("end resetting flag");
		AS_flag_resetDone = false;
	};

	guer_respawn setMarkerPos _position;
	guer_respawn setMarkerAlpha 1;
	if (count (server getVariable ["obj_vehiclePad",[]]) > 0) then {
		[obj_vehiclePad, {deleteVehicle _this}] remoteExec ["call", 0];
		[obj_vehiclePad, {obj_vehiclePad = nil}] remoteExec ["call", 0];
		server setVariable ["AS_vehicleOrientation", 0, true];
		server setVariable ["obj_vehiclePad",[],true];
	};

	if (isMultiplayer) then {hint localize "STR_HINTS_HQPLACE_MOVING"; sleep 5};
	_spawnPos = [_position, 3, getDir petros] call BIS_Fnc_relPos;
	fireX setPos _spawnPos;
	_direction = getdir Petros;
	if (isMultiplayer) then {sleep 5};
	_spawnPos = [getPos fireX, 3, _direction] call BIS_Fnc_relPos;
	boxX setPos _spawnPos;
	_direction = _direction + 45;
	_spawnPos = [getPos fireX, 3, _direction] call BIS_Fnc_relPos;
	mapX setPos _spawnPos;
	mapX setDir ([fireX, mapX] call BIS_fnc_dirTo);
	_direction = _direction + 45;
	_spawnPos = [getPos fireX, 3, _direction] call BIS_Fnc_relPos;
	flagX setPos _spawnPos;
	_direction = _direction + 45;
	_spawnPos = [getPos fireX, 3, _direction] call BIS_Fnc_relPos;
	vehicleBox setPos _spawnPos;

	if (isNil "placementDone") then {
		if (isMultiplayer) then {
			{
				_x setPos getPos petros;
			} forEach playableUnits
		} else {
			Slowhand setPos (getMarkerPos guer_respawn);
		}
	} else {
		Slowhand allowDamage true;
	};

	if (isMultiplayer) then {
		boxX hideObjectGlobal false;
		vehicleBox hideObjectGlobal false;
		mapX hideObjectGlobal false;
		fireX hideObjectGlobal false;
		flagX hideObjectGlobal false;
	} else {
		boxX hideObject false;
		vehicleBox hideObject false;
		mapX hideObject false;
		fireX hideObject false;
		flagX hideObject false;
	};
    LOG("Unlock map");
	openmap [false,false];
};

"FIA_HQ" setMarkerPos (getMarkerPos guer_respawn);
posHQ = getMarkerPos guer_respawn; publicVariable "posHQ";
server setVariable ["posHQ", getMarkerPos guer_respawn, true];

if (isNil "placementDone") then {
	placementDone = true;
	publicVariable "placementDone";
};
LOG("END placementSelection");
