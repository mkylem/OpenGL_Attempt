Entity :: struct {
    using position : Vector3;
    velocity : Vector3;
    ID : u64;

    map: *Texture;
}

Color_Palette :: struct {
    union {
        font:  Vector4;
        one:   Vector4;
    }
    union {
      outline: Vector4;
        two:   Vector4;    
    }
    union {
        fg:    Vector4;
        three: Vector4;
    }
    union {
        bg:    Vector4;
        four:  Vector4;
    }
}

Object_Type :: enum u8 {
    NONE :: 0; // Basically, a hole. Literal "none"
    FLOOR;
    STAIR;
    BOULDER;
    SPIKES;
}

// @Todo: Actually update with a w/e ledger of given enemies. This way I can load & bake the data during compilation since I still want to keep it as one .exe.
Monster_Type :: enum u8 {
    Dead   :: 0;
    Zombie :: 1;
    Mummy  :: 2;
    Ghost  :: 3;
    Dragon :: 4;
}

Monster_Action :: enum_flags u8 {
    STATIONARY :: 0x1;
    FALLING;
    MOVING;
    FLYING;
}

Object :: struct {
    using entity: Entity;

    type: Object_Type;
}

Monster :: struct {
    using entity: Entity;
    
    type: Monster_Type;
    state: Monster_Action;
    alive: bool = true;
}

Player :: struct {
    using entity: Entity;

    alive: bool = true;
}