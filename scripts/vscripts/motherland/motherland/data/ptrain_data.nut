TRAIN_OOB_DOOR_ENTNAME <- "train_door_oob"

PEACEFUL_TRAIN_TEMPLATE_ENTNAMES <- [
    "peaceful_train1_template",
    "peaceful_train2_template"
]

PEACEFUL_TRAIN_ENTNAMES <- [
    "peaceful_train1",
    "peaceful_train2"
]

TRAIN_GATES <- [
    {
        pos = Entities.FindByName(null, "train_gate_entrance").GetOrigin()
        light1 = "train_gate_entrance_light1"
        light2 = "train_gate_entrance_light2"
        sound  = "train_gate_entrance_sound"
        doors  = "train_door_entrance_*"
        distance = 3500
        gateTimer = null
    },
    {
        pos = Entities.FindByName(null, "train_gate_laser").GetOrigin()
        light1 = "train_gate_laser_light1"
        light2 = "train_gate_laser_light2"
        sound  = "train_gate_laser_sound"
        doors  = "train_door_laser_*"
        distance = 2500
        gateTimer = null
    },
    {
        pos = Entities.FindByName(null, "train_gate_exit").GetOrigin()
        light1 = "train_gate_exit_light1"
        light2 = "train_gate_exit_light2"
        sound  = "train_gate_exit_sound"
        doors  = "train_door_exit_*"
        distance = 3500
        gateTimer = null
    }
]