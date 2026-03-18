#+vet explicit-allocators
package src

import "core:time"
Double_Barrel :: struct {
        loaded: int,
        ammo: int,

        state: Double_Barrel_State,
        state_started: time.Tick,
}

Double_Barrel_State :: enum {
        Idle = 0,
        Shoot,
        Reload,
}

double_barrel_animations := [Double_Barrel_State]i32 {
        .Idle = 999,
        .Shoot = 0,
        .Reload = 1,
}
