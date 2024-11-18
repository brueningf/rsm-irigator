import ntp
import esp32 show adjust-real-time-clock
import gpio
import gpio.adc
import gpio.pwm
import system.storage
import .server
import .flash

last-pumped := null 
beeper := gpio.Pin 21 --output

main:
    task --background:: 
        web := WebServer
        web.run 80

    task::
        while true:
            if not is-tank-full:
                // send alert
                12.repeat:
                    buzz beeper --frequency=1300 --ms=(50)
                    sleep --ms=200

                print "tank is empty"
                sleep (Duration --m=1)
                continue

            trigger-pump
            sleep --ms=5000

    led1 := gpio.Pin 27 --output
    led2 := gpio.Pin 26 --output
    led3 := gpio.Pin 25 --output
    led4 := gpio.Pin 13 --output

    // task:: led-driver led1 --step=1
    // task:: led-driver led2 --step=2
    // task:: led-driver led3 --step=3
    // task:: led-driver led4 --step=4

    // alive beep
    task::
        while true:
            buzz beeper --frequency=1500 --ms=(50)
            sleep --ms=100
            buzz beeper --frequency=1400 --ms=(50)
            sleep --ms=600000

trigger-pump:
    flash := Flash
    interval := flash.get "settings/interval" "01:00"
    pump-period := flash.get "settings/pump_period" "05:00"

    bucket := storage.Bucket.open --ram "pump-state"
    tmp-active := bucket.get "tmp-active" --if-absent=: false
    active := bucket.get "active" --init=: true
    bucket.close
    
    if not active:
        print "pump is deactivated"
        return

    interval-duration := Duration --h=(int.parse interval[0..2]) --m=(int.parse interval[3..5])
   
    if last-pumped != null and (last-pumped + interval-duration) > Time.now and not tmp-active:
        time-to-next-pump := (last-pumped + interval-duration).to Time.now
        print "not pumping until next interval in: $time-to-next-pump"
        return
    pump := gpio.Pin 2 --output
    pump.set 0
    
    pump-period-ms := (
        Duration --m=(int.parse pump-period[0..2]) --s=(int.parse pump-period[3..5])
    ).in-ms

    print "pumping"
    sleep --ms=pump-period-ms
    last-pumped = Time.now
    if tmp-active:
        bucket = storage.Bucket.open --ram "pump-state"
        bucket["tmp-active"] = false
        bucket.close
        print "deactivating tmp trigger"

    print "pump off"
    pump.set 1
    pump.close

is-tank-full -> bool:
    pin := gpio.Pin 32 --input
    result := pin.get
    pin.close
    return result == 0

buzz pin --frequency --ms:
    generator := pwm.Pwm --frequency=frequency
    channel := generator.start pin --duty-factor=0.5
    sleep --ms=ms
    channel.close
    generator.close

led-driver led/gpio.Pin --step:
    // Create a PWM square wave generator with frequency 400Hz.
    generator := pwm.Pwm --frequency=400

    // Use it to drive the LED pin.
    // By default the duty factor is 0.
    channel := generator.start led

    duty_percent := 0
    while true:
        // Update the duty factor.
        channel.set_duty_factor duty_percent/100.0
        duty_percent += step
        if duty_percent <= 0 or duty_percent >= 100:
            step = -step
        sleep --ms=10

pulse-generator pin/gpio.Pin:
    2.repeat:
        pin.set 1
        sleep --ms=1000
        pin.set 0
        sleep --ms=1000

update-time:
    set-timezone "<-05>5"
    now := Time.now
    if now < (Time.parse "2022-01-10T00:00:00Z"):
        result ::= ntp.synchronize --server="0.south-america.pool.ntp.org"
        if result:
            adjust-real-time-clock result.adjustment
        else:
            print "ntp: synchronization request failed"
