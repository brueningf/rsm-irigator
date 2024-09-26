import gpio
import gpio.adc
import gpio.pwm
import http
import net
import system

view-index data:
    stats := system.process-stats
    memory := stats[system.STATS-INDEX-ALLOCATED-MEMORY]
    memory-free := stats[system.STATS-INDEX-SYSTEM-FREE-MEMORY]
    memory-reserved := stats[system.STATS-INDEX-RESERVED-MEMORY]
    return """
    <!DOCTYPE html>
        platform: $system.platform / $system.app-sdk-version / $system.program-path <br>
        stats: $stats <br>
        free memory: heap $memory-reserved / allocated $memory | total free $memory-free / largest free $(stats[system.STATS-INDEX-SYSTEM-LARGEST-FREE])
        adc: $data
    </html>
    """

buzz pin --frequency --ms:
  generator := pwm.Pwm --frequency=frequency
  channel := generator.start pin --duty-factor=0.5
  sleep --ms=ms
  channel.close
  generator.close


main:
    pump := gpio.Pin 2 --output

    led1 := gpio.Pin 27 --output
    led2 := gpio.Pin 26 --output
    led3 := gpio.Pin 25 --output
    led4 := gpio.Pin 13 --output

    adc := adc.Adc (gpio.Pin 32 --input)

    beeper := gpio.Pin 21 --output
    rate := adc.get

    task:: 
        while true:
            pulse-generator pump
    task:: led-driver led1 --step=1
    task:: led-driver led2 --step=2
    task:: led-driver led3 --step=3
    // task:: led-driver led4 --step=4

    task::
        while true:
            exception := catch:
                rate = (adc.get * 100)
            buzz beeper --frequency=1600 --ms=(50)
            sleep --ms=(100.0 * rate).to-int


    network := net.open
    server-socket := network.tcp-listen 80
    port := server-socket.local-address.port
    print "Listening on http://$network.address:$port/"

    clients := []
    server := http.Server --max-tasks=2
    server.listen server-socket:: | request/http.RequestIncoming response-writer/http.ResponseWriter |
        if request.path == "/" or request.path == "/index.html":
            response-writer.headers.add "Content-Type" "text/html"
            response-writer.out.write (view-index adc.get)
        else:
            response-writer.write-headers http.STATUS-NOT-FOUND --message="Not Found"

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
