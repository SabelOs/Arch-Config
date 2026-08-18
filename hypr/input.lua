---------------
---- INPUT ----
---------------
hl.device({
    name = "microsoft-surface-type-cover-touchpad",
    enabled = false,
})

hl.config({
    input = {
        kb_layout = "de",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

