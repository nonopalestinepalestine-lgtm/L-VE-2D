-- CRAZY ELEVATOR
-- Responsive 2D Elevator
-- Floor 2 Monster
-- Floor 4 Mechanical Failure
-- Floor 5 Calm False Safety Event
-- Floor 6 Unlocked after Floor 5
-- 20 Second Calm Music
-- Ready to paste

local BASE_W = 800
local BASE_H = 600

local scale = 1
local offsetX = 0
local offsetY = 0

-- =========================================
-- ELEVATOR
-- =========================================

local floor = 0
local targetFloor = 0

local moving = false

local travelTime = 0
local travelTimer = 0

local failureTriggered = false

-- =========================================
-- DOORS
-- =========================================

local doorOpen = false
local doorAmount = 0

local doorSpeed = 0.75

-- =========================================
-- EFFECTS
-- =========================================

local lightTimer = 0
local shakeAmount = 0
local alarmFlash = 0
local horrorFlash = 0

-- =========================================
-- ALARM
-- =========================================

local alarmTimer = 0
local ALARM_DURATION = 10

-- =========================================
-- FLOOR 2 HORROR
-- =========================================

local horrorActive = false
local horrorTimer = 0
local horrorFinished = false

local monsterActive = false
local monsterProgress = 0
local monsterHit = false
local monsterScreamPlayed = false

-- =========================================
-- FLOOR 4 EVENT
-- =========================================

local floor4Active = false
local floor4Timer = 0
local FLOOR4_DURATION = 5

-- =========================================
-- FLOOR 5 EVENT
-- =========================================

local floor5Active = false
local floor5Timer = 0

-- الآن الحدث 20 ثانية
local FLOOR5_DURATION = 20

-- =========================================
-- SOUNDS
-- =========================================

local doorSound
local dingSound
local alarmSound
local moveSound
local repairSound
local monsterScreamSound
local grindingSound
local calmMusic

-- =========================================
-- ELEVATOR FAILURE
-- =========================================

local elevatorBroken = false
local wirePanel = false

-- =========================================
-- WIRES
-- =========================================

local wireColors = {
    red = {1, 0.12, 0.12},
    blue = {0.15, 0.45, 1},
    green = {0.15, 1, 0.25},
    yellow = {1, 0.8, 0.1}
}

local wiresConnected = {
    red = false,
    blue = false,
    green = false,
    yellow = false
}

local selectedWire = nil

local wireLeft = {
    {color = "red", y = 250},
    {color = "blue", y = 310},
    {color = "green", y = 370},
    {color = "yellow", y = 430}
}

local wireRight = {
    {color = "green", y = 250},
    {color = "yellow", y = 310},
    {color = "red", y = 370},
    {color = "blue", y = 430}
}

-- =========================================
-- RESPONSIVE
-- =========================================

function updateScale()

    local screenW, screenH =
        love.graphics.getDimensions()

    scale = math.min(
        screenW / BASE_W,
        screenH / BASE_H
    )

    offsetX =
        (screenW - BASE_W * scale) / 2

    offsetY =
        (screenH - BASE_H * scale) / 2

end

-- =========================================
-- SIMPLE SOUND
-- =========================================

function createBeep(frequency, duration, volume)

    local sampleRate = 44100

    local samples =
        math.floor(sampleRate * duration)

    local data =
        love.sound.newSoundData(
            samples,
            sampleRate,
            16,
            1
        )

    for i = 0, samples - 1 do

        local t =
            i / sampleRate

        local fade =
            1 - (i / samples)

        local value =
            math.sin(
                2 * math.pi * frequency * t
            )

        data:setSample(
            i,
            value * fade * volume
        )

    end

    return love.audio.newSource(
        data,
        "static"
    )

end

-- =========================================
-- CALM FLOOR 5 MUSIC
-- EXACTLY 20 SECONDS
-- =========================================

function createCalmMusic()

    local sampleRate = 44100

    -- الأغنية الآن 20 ثانية
    local duration = 20

    local samples =
        math.floor(
            sampleRate * duration
        )

    local data =
        love.sound.newSoundData(
            samples,
            sampleRate,
            16,
            1
        )

    -- =====================================
    -- 25 نغمة
    -- كل نغمة 0.8 ثانية
    -- 25 × 0.8 = 20 ثانية بالضبط
    -- =====================================

    local melody = {

        -- الجزء الأول
        261.63,
        329.63,
        392.00,
        329.63,
        293.66,

        349.23,
        440.00,
        349.23,
        261.63,
        329.63,

        -- الجزء الثاني
        392.00,
        523.25,
        440.00,
        392.00,
        329.63,

        293.66,
        349.23,
        392.00,
        349.23,
        261.63,

        -- الجزء الأخير
        329.63,
        392.00,
        440.00,
        392.00,
        523.25
    }

    local noteDuration = 0.8

    for i = 0, samples - 1 do

        local t =
            i / sampleRate

        -- =================================
        -- اختيار النغمة
        -- =================================

        local noteIndex =
            math.floor(
                t / noteDuration
            ) + 1

        -- حماية آخر عينة
        if noteIndex > #melody then
            noteIndex = #melody
        end

        local frequency =
            melody[noteIndex]

        -- وقت النغمة الحالية
        local localTime =
            t
            - (
                (noteIndex - 1)
                * noteDuration
            )

        -- =================================
        -- MAIN MELODY
        -- =================================

        local melodyWave =
            math.sin(
                2 * math.pi
                * frequency
                * localTime
            )

        -- =================================
        -- SOFT HARMONY
        -- =================================

        local harmonyWave =
            math.sin(
                2 * math.pi
                * (frequency / 2)
                * localTime
            ) * 0.25

        -- =================================
        -- SOFT BASS
        -- =================================

        local bassWave =
            math.sin(
                2 * math.pi
                * (frequency / 4)
                * localTime
            ) * 0.12

        -- =================================
        -- HIGH SOFT LAYER
        -- =================================

        local softWave =
            math.sin(
                2 * math.pi
                * (frequency * 2)
                * localTime
            ) * 0.06

        -- =================================
        -- NOTE ENVELOPE
        -- =================================

        local noteProgress =
            localTime / noteDuration

        local noteEnvelope = 1

        if noteProgress < 0.08 then

            noteEnvelope =
                noteProgress / 0.08

        elseif noteProgress > 0.82 then

            noteEnvelope =
                (1 - noteProgress) / 0.18

        end

        noteEnvelope =
            math.max(
                0,
                math.min(
                    1,
                    noteEnvelope
                )
            )

        -- =================================
        -- GLOBAL FADE
        -- =================================

        local globalEnvelope = 1

        -- دخول الأغنية بهدوء
        if t < 0.7 then

            globalEnvelope =
                t / 0.7

        -- نهاية الأغنية بهدوء
        elseif t > duration - 1.5 then

            globalEnvelope =
                (duration - t) / 1.5

        end

        globalEnvelope =
            math.max(
                0,
                math.min(
                    1,
                    globalEnvelope
                )
            )

        -- =================================
        -- FINAL SOUND
        -- =================================

        local value =
            (
                melodyWave * 0.32
                + harmonyWave
                + bassWave
                + softWave
            )

        data:setSample(
            i,
            value
            * noteEnvelope
            * globalEnvelope
            * 0.24
        )

    end

    return love.audio.newSource(
        data,
        "static"
    )

end

-- =========================================
-- SIREN
-- =========================================

function createSiren(volume)

    local sampleRate = 44100
    local duration = 0.5

    local samples =
        math.floor(sampleRate * duration)

    local data =
        love.sound.newSoundData(
            samples,
            sampleRate,
            16,
            1
        )

    for i = 0, samples - 1 do

        local t =
            i / sampleRate

        local frequency

        if math.floor(t * 4) % 2 == 0 then
            frequency = 1100
        else
            frequency = 650
        end

        local value =
            math.sin(
                2 * math.pi
                * frequency
                * t
            )

        data:setSample(
            i,
            value * volume
        )

    end

    return love.audio.newSource(
        data,
        "static"
    )

end

-- =========================================
-- MONSTER SCREAM
-- =========================================

function createMonsterScream()

    local sampleRate = 44100
    local duration = 1.35

    local samples =
        math.floor(
            sampleRate * duration
        )

    local data =
        love.sound.newSoundData(
            samples,
            sampleRate,
            16,
            1
        )

    for i = 0, samples - 1 do

        local t =
            i / sampleRate

        local progress =
            t / duration

        local baseFrequency =
            520 - progress * 300

        local vibrato =
            math.sin(
                2 * math.pi * 6 * t
            ) * 75

        local frequency =
            math.max(
                120,
                baseFrequency + vibrato
            )

        local phase =
            2 * math.pi
            * frequency
            * t

        local low =
            math.sin(phase)

        local harmonic2 =
            math.sin(phase * 2) * 0.38

        local harmonic3 =
            math.sin(phase * 3) * 0.22

        local harmonic4 =
            math.sin(phase * 4) * 0.12

        local noise =
            (math.random() * 2 - 1)
            * 0.20

        local envelope = 1

        if t < 0.08 then

            envelope =
                t / 0.08

        elseif t > duration - 0.45 then

            envelope =
                (duration - t) / 0.45

        end

        envelope =
            math.max(
                0,
                math.min(
                    1,
                    envelope
                )
            )

        local value =
            low * 0.72
            + harmonic2
            + harmonic3
            + harmonic4
            + noise

        value =
            math.tanh(
                value * 1.35
            )

        data:setSample(
            i,
            value
            * envelope
            * 0.52
        )

    end

    return love.audio.newSource(
        data,
        "static"
    )

end

-- =========================================
-- FLOOR 4 GRINDING SOUND
-- =========================================

function createGrindingSound()

    local sampleRate = 44100
    local duration = 1.2

    local samples =
        math.floor(sampleRate * duration)

    local data =
        love.sound.newSoundData(
            samples,
            sampleRate,
            16,
            1
        )

    for i = 0, samples - 1 do

        local t =
            i / sampleRate

        local low =
            math.sin(
                2 * math.pi * 72 * t
            )

        local metal =
            math.sin(
                2 * math.pi * 137 * t
                + math.sin(
                    2 * math.pi * 4 * t
                ) * 3
            )

        local rough =
            math.sin(
                2 * math.pi * 245 * t
            )

        local noise =
            (math.random() * 2 - 1)

        local value =
            low * 0.38
            + metal * 0.30
            + rough * 0.12
            + noise * 0.20

        value =
            math.tanh(
                value * 1.8
            )

        data:setSample(
            i,
            value * 0.24
        )

    end

    return love.audio.newSource(
        data,
        "static"
    )

end

-- =========================================
-- LOAD
-- =========================================

function love.load()

    floor = 0
    targetFloor = 0

    moving = false

    doorOpen = false
    doorAmount = 0

    travelTime = 0
    travelTimer = 0

    failureTriggered = false

    lightTimer = 0
    shakeAmount = 0
    alarmFlash = 0
    horrorFlash = 0

    alarmTimer = 0

    elevatorBroken = false
    wirePanel = false

    selectedWire = nil

    horrorActive = false
    horrorTimer = 0
    horrorFinished = false

    monsterActive = false
    monsterProgress = 0
    monsterHit = false
    monsterScreamPlayed = false

    floor4Active = false
    floor4Timer = 0

    floor5Active = false
    floor5Timer = 0

    for color, value in pairs(wiresConnected) do
        wiresConnected[color] = false
    end

    updateScale()

    -- =====================================
    -- SOUNDS
    -- =====================================

    doorSound =
        createBeep(
            180,
            0.12,
            0.18
        )

    dingSound =
        createBeep(
            900,
            0.20,
            0.20
        )

    alarmSound =
        createSiren(
            0.38
        )

    moveSound =
        createBeep(
            70,
            0.35,
            0.08
        )

    repairSound =
        createBeep(
            650,
            0.15,
            0.18
        )

    monsterScreamSound =
        createMonsterScream()

    grindingSound =
        createGrindingSound()

    calmMusic =
        createCalmMusic()

end

function love.resize()

    updateScale()

end

-- =========================================
-- ALARM
-- =========================================

function startAlarm()

    alarmTimer =
        ALARM_DURATION

    alarmFlash = 1

    if alarmSound then

        alarmSound:stop()

        alarmSound:setLooping(true)

        alarmSound:play()

    end

end

-- =========================================
-- WIRES
-- =========================================

function allWiresConnected()

    for color, connected in pairs(wiresConnected) do

        if not connected then
            return false
        end

    end

    return true

end

-- =========================================
-- FAILURE
-- =========================================

function triggerElevatorFailure()

    moving = false

    elevatorBroken = true
    wirePanel = true

    failureTriggered = true

    doorOpen = false

    shakeAmount = 0

end

-- =========================================
-- FLOOR 2 HORROR
-- =========================================

function startFloor2Horror()

    horrorActive = true

    horrorTimer = 0

    horrorFinished = false

    doorOpen = false

    monsterActive = false
    monsterProgress = 0
    monsterHit = false
    monsterScreamPlayed = false

    horrorFlash = 0

end

-- =========================================
-- FLOOR 4 EVENT
-- =========================================

function startFloor4Event()

    floor4Active = true

    floor4Timer = 0

    doorOpen = false

    shakeAmount = 0

    if grindingSound then

        grindingSound:stop()

        grindingSound:setLooping(true)

        grindingSound:play()

    end

end

-- =========================================
-- FLOOR 5 EVENT
-- =========================================

function startFloor5Event()

    floor5Active = true

    floor5Timer = 0

    doorOpen = true

    -- تشغيل الأغنية الهادئة لمدة 20 ثانية
    if calmMusic then

        calmMusic:stop()

        calmMusic:setLooping(false)

        calmMusic:play()

    end

end

-- =========================================
-- UPDATE
-- =========================================

function love.update(dt)

    lightTimer =
        lightTimer + dt

    alarmFlash =
        math.max(
            0,
            alarmFlash - dt * 2
        )

    horrorFlash =
        math.max(
            0,
            horrorFlash - dt * 3
        )

    -- =====================================
    -- ALARM
    -- =====================================

    if alarmTimer > 0 then

        alarmTimer =
            math.max(
                0,
                alarmTimer - dt
            )

        if alarmTimer <= 0 then

            if alarmSound then
                alarmSound:stop()
            end

        end

    end

    -- =====================================
    -- FLOOR 4
    -- =====================================

    if floor4Active then

        floor4Timer =
            floor4Timer + dt

        shakeAmount =
            math.sin(
                floor4Timer * 55
            ) * 6

        if math.random() > 0.82 then

            shakeAmount =
                shakeAmount
                + (
                    math.random() * 4 - 2
                )

        end

        if floor4Timer >= FLOOR4_DURATION then

            floor4Active = false

            floor4Timer = 0

            shakeAmount = 0

            if grindingSound then
                grindingSound:stop()
            end

            doorOpen = true

        end

    end

    -- =====================================
    -- FLOOR 5
    -- =====================================

    if floor5Active then

        floor5Timer =
            floor5Timer + dt

        -- بعد 3 ثواني تبدأ الغرابة
        if floor5Timer >= 3 then

            if math.random() > 0.90 then

                shakeAmount =
                    (
                        math.random() * 2 - 1
                    ) * 1.5

            else

                shakeAmount = 0

            end

        end

        -- بعد 20 ثانية ينتهي الحدث
        if floor5Timer >= FLOOR5_DURATION then

            floor5Active = false

            floor5Timer = 0

            shakeAmount = 0

            doorOpen = true

            if calmMusic then
                calmMusic:stop()
            end

        end

    end

    -- =====================================
    -- FLOOR 2 HORROR
    -- =====================================

    if horrorActive then

        horrorTimer =
            horrorTimer + dt

        if horrorTimer >= 2
        and horrorTimer < 2 + dt then

            doorOpen = true

            if doorSound then

                doorSound:stop()
                doorSound:play()

            end

        end

        if horrorTimer >= 3.05 then

            monsterActive = true

            local monsterStart = 3.05
            local monsterDuration = 0.95

            monsterProgress =
                math.min(
                    1,
                    (
                        horrorTimer
                        - monsterStart
                    )
                    / monsterDuration
                )

            if not monsterScreamPlayed then

                monsterScreamPlayed = true

                if monsterScreamSound then

                    monsterScreamSound:stop()
                    monsterScreamSound:play()

                end

            end

            if monsterProgress >= 1
            and not monsterHit then

                monsterHit = true

                horrorFlash = 1

                shakeAmount = 8

            end

        end

        if monsterHit then

            shakeAmount =
                math.max(
                    0,
                    shakeAmount - dt * 28
                )

        end

        if horrorTimer >= 4.75
        and horrorTimer < 4.75 + dt then

            monsterActive = false
            monsterHit = false

        end

        if horrorTimer >= 5
        and horrorTimer < 5 + dt then

            doorOpen = false

            if doorSound then

                doorSound:stop()
                doorSound:play()

            end

        end

        if horrorTimer >= 7 then

            horrorActive = false

            horrorFinished = true

            monsterActive = false
            monsterHit = false

        end

    end

    -- =====================================
    -- DOORS
    -- =====================================

    if doorOpen then

        doorAmount =
            math.min(
                1,
                doorAmount + doorSpeed * dt
            )

    else

        doorAmount =
            math.max(
                0,
                doorAmount - doorSpeed * dt
            )

    end

    -- =====================================
    -- MOVEMENT
    -- =====================================

    if moving then

        travelTimer =
            travelTimer + dt

        shakeAmount =
            math.sin(
                travelTimer * 35
            ) * 2.2

        -- =================================
        -- FAILURE 1 → 2
        -- =================================

        if not failureTriggered
        and floor == 1
        and targetFloor == 2
        and travelTimer >= travelTime * 0.45 then

            triggerElevatorFailure()

            return

        end

        -- =================================
        -- ARRIVAL
        -- =================================

        if travelTimer >= travelTime then

            travelTimer =
                travelTime

            floor =
                targetFloor

            moving = false

            shakeAmount = 0

            doorOpen = true

            failureTriggered = false

            if dingSound then

                dingSound:stop()
                dingSound:play()

            end

            -- =================================
            -- FLOOR 2
            -- =================================

            if floor == 2
            and not horrorFinished then

                startFloor2Horror()

            end

            -- =================================
            -- FLOOR 4
            -- =================================

            if floor == 4 then

                startFloor4Event()

            end

            -- =================================
            -- FLOOR 5
            -- =================================

            if floor == 5 then

                startFloor5Event()

            end

        end

    else

        if not monsterHit
        and not floor4Active
        and not floor5Active then

            shakeAmount = 0

        end

    end

end

-- =========================================
-- DRAW
-- =========================================

function love.draw()

    love.graphics.clear(
        0.01,
        0.01,
        0.015
    )

    love.graphics.push()

    love.graphics.translate(
        offsetX,
        offsetY
    )

    love.graphics.scale(
        scale,
        scale
    )

    -- =====================================
    -- BACKGROUND
    -- =====================================

    love.graphics.setColor(
        0.015,
        0.015,
        0.02
    )

    love.graphics.rectangle(
        "fill",
        0,
        0,
        BASE_W,
        BASE_H
    )

    -- =====================================
    -- ELEVATOR FRAME
    -- =====================================

    love.graphics.setColor(
        0.05,
        0.05,
        0.06
    )

    love.graphics.rectangle(
        "fill",
        130,
        45,
        540,
        515
    )

    love.graphics.setColor(
        0.18,
        0.18,
        0.20
    )

    love.graphics.setLineWidth(5)

    love.graphics.rectangle(
        "line",
        130,
        45,
        540,
        515
    )

    -- =====================================
    -- SHAKE
    -- =====================================

    love.graphics.push()

    love.graphics.translate(
        shakeAmount,
        0
    )

    -- =====================================
    -- YELLOW WALL
    -- =====================================

    local wallDarkness = 0

    if floor5Active
    and floor5Timer >= 3 then

        local change =
            math.min(
                1,
                (floor5Timer - 3) / 3
            )

        wallDarkness =
            change * 0.32

    end

    love.graphics.setColor(
        0.55 - wallDarkness,
        0.42 - wallDarkness * 0.75,
        0.08 - wallDarkness * 0.15
    )

    love.graphics.rectangle(
        "fill",
        180,
        80,
        440,
        440
    )

    -- =====================================
    -- FLOOR 2 DARKNESS
    -- =====================================

    if floor == 2
    and doorAmount > 0.05 then

        love.graphics.setColor(
            0.005,
            0.002,
            0.003
        )

        love.graphics.rectangle(
            "fill",
            280,
            140,
            240,
            285
        )

        if horrorActive then

            local redPulse =
                (
                    math.sin(
                        horrorTimer * 8
                    ) + 1
                ) / 2

            love.graphics.setColor(
                1,
                0.02,
                0.02,
                0.35
                + redPulse * 0.45
            )

            love.graphics.circle(
                "fill",
                400,
                250,
                12
            )

        end

    end

    -- =====================================
    -- FLOOR 5 CHANGE
    -- =====================================

    if floor5Active
    and floor5Timer >= 3
    and doorAmount > 0.05 then

        local change =
            math.min(
                1,
                (floor5Timer - 3) / 2.5
            )

        love.graphics.setColor(
            0.005,
            0.003,
            0.003,
            0.35
            + change * 0.45
        )

        love.graphics.rectangle(
            "fill",
            315,
            180,
            170,
            245
        )

        love.graphics.setColor(
            0.65,
            0.01,
            0.01,
            change * 0.55
        )

        love.graphics.rectangle(
            "fill",
            350,
            285,
            100,
            3
        )

    end

    -- =====================================
    -- WALL DETAILS
    -- =====================================

    local detailAlpha = 1

    if floor5Active
    and floor5Timer >= 3 then

        detailAlpha =
            math.max(
                0,
                1
                - (
                    floor5Timer - 3
                ) / 2
            )

    end

    love.graphics.setColor(
        0.35,
        0.25,
        0.04,
        detailAlpha
    )

    love.graphics.setLineWidth(3)

    love.graphics.line(
        205,
        110,
        205,
        445
    )

    love.graphics.line(
        515,
        110,
        515,
        445
    )

    love.graphics.line(
        190,
        430,
        610,
        430
    )

    -- =====================================
    -- FLOOR
    -- =====================================

    love.graphics.setColor(
        0.08,
        0.07,
        0.06
    )

    love.graphics.rectangle(
        "fill",
        180,
        445,
        440,
        75
    )

    for x = 190, 600, 40 do

        love.graphics.setColor(
            0.16,
            0.13,
            0.09
        )

        love.graphics.line(
            x,
            445,
            x,
            520
        )

    end

    -- =====================================
    -- CEILING
    -- =====================================

    love.graphics.setColor(
        0.20,
        0.17,
        0.08
    )

    love.graphics.rectangle(
        "fill",
        180,
        80,
        440,
        35
    )

    -- =====================================
    -- LIGHT
    -- =====================================

    local pulse =
        (
            math.sin(
                lightTimer * 4
            ) + 1
        ) / 2

    if floor == 2
    and horrorActive then

        local flicker =
            math.random()

        if flicker > 0.25 then

            love.graphics.setColor(
                1,
                0.95,
                0.65,
                0.08
            )

        else

            love.graphics.setColor(
                0,
                0,
                0,
                0
            )

        end

    elseif floor4Active then

        if math.random() > 0.2 then

            love.graphics.setColor(
                1,
                0.75,
                0.35,
                0.08
            )

        else

            love.graphics.setColor(
                0,
                0,
                0,
                0
            )

        end

    elseif floor5Active
    and floor5Timer >= 3 then

        local flicker =
            math.sin(
                floor5Timer * 18
            )

        if flicker > -0.15 then

            love.graphics.setColor(
                1,
                0.95,
                0.65,
                0.055
            )

        else

            love.graphics.setColor(
                0,
                0,
                0,
                0
            )

        end

    else

        love.graphics.setColor(
            1,
            0.95,
            0.65,
            0.04
            + pulse * 0.04
        )

    end

    love.graphics.rectangle(
        "fill",
        235,
        105,
        330,
        50
    )

    love.graphics.setColor(
        1,
        0.95,
        0.75
    )

    love.graphics.rectangle(
        "fill",
        285,
        108,
        230,
        12
    )

    -- =====================================
    -- FLOOR DISPLAY
    -- =====================================

    love.graphics.setColor(
        0.025,
        0.025,
        0.03
    )

    love.graphics.rectangle(
        "fill",
        300,
        30,
        200,
        48
    )

    if floor5Active
    and floor5Timer >= 3 then

        local flick =
            math.sin(
                floor5Timer * 13
            )

        if flick > -0.3 then

            love.graphics.setColor(
                0.25,
                1,
                0.35
            )

        else

            love.graphics.setColor(
                0.04,
                0.15,
                0.05
            )

        end

    else

        love.graphics.setColor(
            0.25,
            1,
            0.35
        )

    end

    love.graphics.printf(
        tostring(floor),
        350,
        38,
        100,
        "center"
    )

    -- =====================================
    -- ARROW
    -- =====================================

    love.graphics.setColor(
        0.5,
        0.9,
        0.55
    )

    if moving then

        if targetFloor > floor then

            love.graphics.printf(
                "▲",
                455,
                42,
                30,
                "center"
            )

        else

            love.graphics.printf(
                "▼",
                455,
                42,
                30,
                "center"
            )

        end

    end

    -- =====================================
    -- DOOR SHADOW
    -- =====================================

    love.graphics.setColor(
        0,
        0,
        0,
        0.5
    )

    love.graphics.rectangle(
        "fill",
        275,
        415,
        250,
        18
    )

    -- =====================================
    -- DARK AREA
    -- =====================================

    love.graphics.setColor(
        0.005,
        0.005,
        0.008
    )

    love.graphics.rectangle(
        "fill",
        280,
        140,
        240,
        285
    )

    -- =====================================
    -- MONSTER
    -- =====================================

    if monsterActive
    and floor == 2
    and doorAmount > 0.05 then

        local p =
            monsterProgress

        local monsterScale =
            0.20 + p * 2.35

        local monsterY =
            315 - p * 25

        local headRadius =
            20 * monsterScale

        love.graphics.setColor(
            0.002,
            0.001,
            0.001
        )

        love.graphics.circle(
            "fill",
            400,
            monsterY - 65 * monsterScale,
            headRadius
        )

        love.graphics.rectangle(
            "fill",
            392 - 5 * monsterScale,
            monsterY - 48 * monsterScale,
            16 * monsterScale,
            30 * monsterScale
        )

        love.graphics.polygon(
            "fill",

            375 - 22 * monsterScale,
            monsterY - 30 * monsterScale,

            425 + 22 * monsterScale,
            monsterY - 30 * monsterScale,

            455 + 28 * monsterScale,
            monsterY + 105 * monsterScale,

            345 - 28 * monsterScale,
            monsterY + 105 * monsterScale
        )

        love.graphics.polygon(
            "fill",

            375 - 18 * monsterScale,
            monsterY - 20 * monsterScale,

            355 - 35 * monsterScale,
            monsterY + 85 * monsterScale,

            365 - 42 * monsterScale,
            monsterY + 90 * monsterScale,

            395 - 8 * monsterScale,
            monsterY + 5 * monsterScale
        )

        love.graphics.polygon(
            "fill",

            425 + 18 * monsterScale,
            monsterY - 20 * monsterScale,

            445 + 35 * monsterScale,
            monsterY + 85 * monsterScale,

            435 + 42 * monsterScale,
            monsterY + 90 * monsterScale,

            405 + 8 * monsterScale,
            monsterY + 5 * monsterScale
        )

        local eyeSize =
            math.max(
                2,
                3.5 * monsterScale
            )

        love.graphics.setColor(
            1,
            0.02,
            0.02
        )

        love.graphics.circle(
            "fill",
            390 - 4 * monsterScale,
            monsterY - 70 * monsterScale,
            eyeSize
        )

        love.graphics.circle(
            "fill",
            410 + 4 * monsterScale,
            monsterY - 70 * monsterScale,
            eyeSize
        )

        if p > 0.65 then

            love.graphics.setColor(
                0.20,
                0,
                0
            )

            love.graphics.ellipse(
                "fill",
                400,
                monsterY - 40 * monsterScale,
                10 * monsterScale,
                18 * monsterScale
            )

        end

    end

    -- =====================================
    -- WHITE DOORS
    -- =====================================

    local doorOffset =
        120 * doorAmount

    love.graphics.setColor(
        0.88,
        0.88,
        0.86
    )

    love.graphics.rectangle(
        "fill",
        280 - doorOffset,
        140,
        120,
        285
    )

    love.graphics.rectangle(
        "fill",
        400 + doorOffset,
        140,
        120,
        285
    )

    -- =====================================
    -- DOOR SHINE
    -- =====================================

    love.graphics.setColor(
        1,
        1,
        1,
        0.25
    )

    love.graphics.rectangle(
        "fill",
        295 - doorOffset,
        150,
        4,
        265
    )

    love.graphics.rectangle(
        "fill",
        501 + doorOffset,
        150,
        4,
        265
    )

    -- =====================================
    -- DOOR EDGES
    -- =====================================

    love.graphics.setColor(
        0.25,
        0.25,
        0.25
    )

    love.graphics.setLineWidth(3)

    love.graphics.rectangle(
        "line",
        280 - doorOffset,
        140,
        120,
        285
    )

    love.graphics.rectangle(
        "line",
        400 + doorOffset,
        140,
        120,
        285
    )

    -- =====================================
    -- BUTTON PANEL
    -- =====================================

    love.graphics.setColor(
        0.035,
        0.035,
        0.04
    )

    love.graphics.rectangle(
        "fill",
        530,
        175,
        70,
        270
    )

    love.graphics.setColor(
        0.30,
        0.25,
        0.12
    )

    love.graphics.setLineWidth(2)

    love.graphics.rectangle(
        "line",
        530,
        175,
        70,
        270
    )

    -- =====================================
    -- UP
    -- =====================================

    local upDisabled =
        moving
        or elevatorBroken
        or horrorActive
        or floor4Active
        or floor5Active

    if upDisabled then

        love.graphics.setColor(
            0.10,
            0.10,
            0.12
        )

    else

        love.graphics.setColor(
            0.08,
            0.32,
            0.55
        )

    end

    love.graphics.rectangle(
        "fill",
        540,
        195,
        50,
        55
    )

    love.graphics.setColor(
        0.5,
        0.8,
        1
    )

    love.graphics.rectangle(
        "line",
        540,
        195,
        50,
        55
    )

    love.graphics.setColor(
        1,
        1,
        1
    )

    love.graphics.printf(
        "▲",
        540,
        205,
        50,
        "center"
    )

    love.graphics.setFont(
        love.graphics.newFont(11)
    )

    love.graphics.printf(
        "UP",
        540,
        228,
        50,
        "center"
    )

    -- =====================================
    -- OPEN
    -- =====================================

    love.graphics.setColor(
        0.08,
        0.32,
        0.55
    )

    love.graphics.rectangle(
        "fill",
        540,
        275,
        50,
        40
    )

    love.graphics.setColor(
        0.4,
        0.75,
        1
    )

    love.graphics.rectangle(
        "line",
        540,
        275,
        50,
        40
    )

    love.graphics.setColor(
        1,
        1,
        1
    )

    love.graphics.printf(
        "◀▶",
        540,
        285,
        50,
        "center"
    )

    -- =====================================
    -- CLOSE
    -- =====================================

    love.graphics.setColor(
        0.55,
        0.10,
        0.10
    )

    love.graphics.rectangle(
        "fill",
        540,
        325,
        50,
        40
    )

    love.graphics.setColor(
        1,
        0.35,
        0.35
    )

    love.graphics.rectangle(
        "line",
        540,
        325,
        50,
        40
    )

    love.graphics.setColor(
        1,
        1,
        1
    )

    love.graphics.printf(
        "><",
        540,
        335,
        50,
        "center"
    )

    -- =====================================
    -- ALARM
    -- =====================================

    love.graphics.setColor(
        0.55,
        0.03,
        0.03
    )

    love.graphics.circle(
        "fill",
        565,
        410,
        16
    )

    if alarmFlash > 0 then

        love.graphics.setColor(
            1,
            0.1,
            0.1,
            alarmFlash
        )

        love.graphics.circle(
            "fill",
            565,
            410,
            27
        )

    end

    love.graphics.setColor(
        1,
        0.2,
        0.2
    )

    love.graphics.circle(
        "fill",
        565,
        410,
        8
    )

    love.graphics.setColor(
        1,
        1,
        1
    )

    love.graphics.printf(
        "!",
        557,
        402,
        16,
        "center"
    )

    love.graphics.pop()

    -- =====================================
    -- MOVING TEXT
    -- =====================================

    if moving then

        love.graphics.setColor(
            1,
            0.75,
            0.15
        )

        love.graphics.printf(
            "MOVING...",
            250,
            535,
            300,
            "center"
        )

    end

    -- =====================================
    -- FLOOR 2 TEXT
    -- =====================================

    if horrorActive then

        love.graphics.setColor(
            1,
            0.08,
            0.08
        )

        love.graphics.printf(
            "........",
            250,
            535,
            300,
            "center"
        )

    end

    -- =====================================
    -- FLOOR 4 TEXT
    -- =====================================

    if floor4Active then

        love.graphics.setColor(
            1,
            0.55,
            0.10
        )

        love.graphics.printf(
            "SYSTEM INSTABILITY...",
            200,
            535,
            400,
            "center"
        )

    end

    -- =====================================
    -- FLOOR 5 TEXT
    -- =====================================

    if floor5Active
    and floor5Timer < 3 then

        love.graphics.setColor(
            0.7,
            0.7,
            0.7
        )

        love.graphics.printf(
            "ALL SYSTEMS NORMAL",
            200,
            535,
            400,
            "center"
        )

    elseif floor5Active
    and floor5Timer >= 3 then

        love.graphics.setColor(
            0.65,
            0.05,
            0.05
        )

        love.graphics.printf(
            "............",
            200,
            535,
            400,
            "center"
        )

    end

    -- =====================================
    -- FLOOR 5 MUSIC TIMER
    -- =====================================

    if floor5Active then

        love.graphics.setColor(
            0.75,
            0.75,
            0.75
        )

        local remaining =
            math.max(
                0,
                math.ceil(
                    FLOOR5_DURATION
                    - floor5Timer
                )
            )

        love.graphics.printf(
            "MUSIC: "
            .. tostring(remaining)
            .. "s",
            200,
            505,
            400,
            "center"
        )

    end

    -- =====================================
    -- HORROR FLASH
    -- =====================================

    if horrorFlash > 0 then

        love.graphics.setColor(
            1,
            0,
            0,
            horrorFlash * 0.25
        )

        love.graphics.rectangle(
            "fill",
            0,
            0,
            BASE_W,
            BASE_H
        )

    end

    -- =====================================
    -- WIRE PANEL
    -- =====================================

    if wirePanel then

        drawWirePanel()

    end

    love.graphics.pop()

end

-- =========================================
-- WIRE PANEL
-- =========================================

function drawWirePanel()

    love.graphics.setColor(
        0.01,
        0.01,
        0.015,
        0.94
    )

    love.graphics.rectangle(
        "fill",
        0,
        0,
        BASE_W,
        BASE_H
    )

    love.graphics.setColor(
        0.07,
        0.07,
        0.08
    )

    love.graphics.rectangle(
        "fill",
        120,
        100,
        560,
        400
    )

    love.graphics.setColor(
        0.25,
        0.25,
        0.28
    )

    love.graphics.setLineWidth(4)

    love.graphics.rectangle(
        "line",
        120,
        100,
        560,
        400
    )

    love.graphics.setColor(
        1,
        0.35,
        0.15
    )

    love.graphics.printf(
        "ELEVATOR SYSTEM FAILURE",
        150,
        125,
        500,
        "center"
    )

    love.graphics.setColor(
        1,
        1,
        1
    )

    love.graphics.printf(
        "CONNECT THE WIRES",
        150,
        155,
        500,
        "center"
    )

    for _, wire in ipairs(wireLeft) do

        local color =
            wireColors[wire.color]

        love.graphics.setColor(
            color[1],
            color[2],
            color[3]
        )

        love.graphics.circle(
            "fill",
            220,
            wire.y,
            12
        )

        love.graphics.setColor(
            0.8,
            0.8,
            0.8
        )

        love.graphics.circle(
            "line",
            220,
            wire.y,
            15
        )

    end

    for _, wire in ipairs(wireRight) do

        local color =
            wireColors[wire.color]

        love.graphics.setColor(
            color[1],
            color[2],
            color[3]
        )

        love.graphics.circle(
            "fill",
            580,
            wire.y,
            12
        )

        love.graphics.setColor(
            0.8,
            0.8,
            0.8
        )

        love.graphics.circle(
            "line",
            580,
            wire.y,
            15
        )

    end

    local leftPositions = {
        red = 250,
        blue = 310,
        green = 370,
        yellow = 430
    }

    local rightPositions = {
        red = 370,
        blue = 430,
        green = 250,
        yellow = 310
    }

    for colorName, connected in pairs(wiresConnected) do

        if connected then

            local color =
                wireColors[colorName]

            love.graphics.setColor(
                color[1],
                color[2],
                color[3]
            )

            love.graphics.setLineWidth(7)

            love.graphics.line(
                220,
                leftPositions[colorName],
                580,
                rightPositions[colorName]
            )

        end

    end

    if selectedWire then

        love.graphics.setColor(
            1,
            1,
            1
        )

        love.graphics.setLineWidth(4)

        love.graphics.circle(
            "line",
            220,
            selectedWire.y,
            20
        )

    end

    love.graphics.setColor(
        0.15,
        0.45,
        0.20
    )

    love.graphics.rectangle(
        "fill",
        300,
        465,
        200,
        30
    )

    love.graphics.setColor(
        1,
        1,
        1
    )

    love.graphics.printf(
        "REPAIR",
        300,
        472,
        200,
        "center"
    )

end

-- =========================================
-- MOUSE / TOUCH
-- =========================================

function love.mousepressed(
    x,
    y,
    button
)

    if button ~= 1 then
        return
    end

    local gameX =
        (x - offsetX) / scale

    local gameY =
        (y - offsetY) / scale

    -- =====================================
    -- WIRE PANEL
    -- =====================================

    if wirePanel then

        for _, wire in ipairs(wireLeft) do

            if math.abs(
                gameY - wire.y
            ) <= 20

            and math.abs(
                gameX - 220
            ) <= 25 then

                if not wiresConnected[
                    wire.color
                ] then

                    selectedWire = wire

                end

                return

            end

        end

        if selectedWire then

            for _, wire in ipairs(wireRight) do

                if math.abs(
                    gameY - wire.y
                ) <= 20

                and math.abs(
                    gameX - 580
                ) <= 25 then

                    if wire.color ==
                        selectedWire.color then

                        wiresConnected[
                            selectedWire.color
                        ] = true

                        selectedWire = nil

                        if repairSound then

                            repairSound:stop()
                            repairSound:play()

                        end

                        if allWiresConnected() then

                            elevatorBroken = false

                            wirePanel = false

                            moving = true

                            if moveSound then

                                moveSound:stop()
                                moveSound:play()

                            end

                        end

                    else

                        startAlarm()

                    end

                    return

                end

            end

        end

        return

    end

    -- =====================================
    -- MOVING
    -- =====================================

    if moving then
        return
    end

    -- =====================================
    -- HORROR
    -- =====================================

    if horrorActive then
        return
    end

    -- =====================================
    -- FLOOR 4 EVENT
    -- =====================================

    if floor4Active then
        return
    end

    -- =====================================
    -- FLOOR 5 EVENT
    -- =====================================

    if floor5Active then
        return
    end

    -- =====================================
    -- UP
    -- =====================================

    if gameX >= 540
    and gameX <= 590
    and gameY >= 195
    and gameY <= 250 then

        if elevatorBroken then
            return
        end

        -- الآن نسمح بالطابق السادس
        if floor >= 6 then
            return
        end

        targetFloor =
            floor + 1

        doorOpen = false

        local floors =
            math.abs(
                targetFloor - floor
            )

        travelTime =
            floors * 2.8

        travelTimer = 0

        moving = true

        if floor == 1
        and targetFloor == 2 then

            failureTriggered = false

        else

            failureTriggered = true

        end

        if moveSound then

            moveSound:stop()
            moveSound:play()

        end

        return

    end

    -- =====================================
    -- OPEN
    -- =====================================

    if gameX >= 540
    and gameX <= 590
    and gameY >= 275
    and gameY <= 315 then

        if not moving
        and not horrorActive
        and not floor4Active
        and not floor5Active then

            doorOpen = true

            if doorSound then

                doorSound:stop()
                doorSound:play()

            end

        end

        return

    end

    -- =====================================
    -- CLOSE
    -- =====================================

    if gameX >= 540
    and gameX <= 590
    and gameY >= 325
    and gameY <= 365 then

        if not moving
        and not horrorActive
        and not floor4Active
        and not floor5Active then

            doorOpen = false

            if doorSound then

                doorSound:stop()
                doorSound:play()

            end

        end

        return

    end

    -- =====================================
    -- ALARM
    -- =====================================

    if gameX >= 545
    and gameX <= 585
    and gameY >= 390
    and gameY <= 430 then

        startAlarm()

        return

    end

end
