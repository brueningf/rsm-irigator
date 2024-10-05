index data:
    return """
<!DOCTYPE html>
<html>
    <head>
        <title>RSM-IRRIGATOR</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdn.tailwindcss.com"></script>
        <script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/mask@3.x.x/dist/cdn.min.js"></script>
        <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
        <script>
            window.data = $data;
        
            document.addEventListener('alpine:init', () => {
                Alpine.data('irigator', () => ({
                    loading: false,
                    interval: window.data.interval,
                    pump_period: window.data.pump_period,
                    tank_level: window.data.tank_level,
                    tmp_active: false,
                    pump_active: window.data.pump_active,
                    sendTrigger() {
                        fetch('/pump-trigger', {
                            method: 'POST',
                        }).then(() => {
                            this.tmp_active = true
                            setTimeout(() => this.tmp_active = false, 1000)
                        })
                    },
                    togglePump() {
                        fetch('/toggle-pump', {
                            method: 'POST',
                        }).then(() => this.pump_active = !this.pump_active)
                    },
                    handle(e) {
                        this.loading = true
                        const formData = new FormData(e.target);
                        const jsonObject = {};
            
                        formData.forEach((value, key) => {
                            jsonObject[key] = value;
                        });
            
                        fetch('/settings', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                            },
                            body: JSON.stringify(jsonObject),
                        }).then(() => this.loading = false)
                    }
                }))
            })
        </script>
    </head>
    <body>
        <main x-data="irigator()" class="container mx-auto max-w-sm p-2">
            <div class="mt-2 p-4 border border-black">
                 <div class="flex items-center justify-between">
                    <span>Nivel de tanque</span>
                    <span class="w-8 h-8 rounded-full" :class="tank_level ? 'bg-green-500' : 'bg-red-500 animate-pulse'"></span>
                </div>
            </div>
            <div class=" w-full p-4 bg-gray-200 border border-black my-4">
                <h3 class="font-bold text-sm border-b border-black">Funciones</h3>
                <div class="grid grid-cols-2 gap-4 my-2">
                    <span>Activar la bomba por el tiempo configurado</span>
                    <button class="p-5 border border-black shadow" :class="tmp_active ? 'bg-green-200 animate-pulse' : ''" x-on:click="sendTrigger">Accionar bomba (temporal)</button>
                    <span>Activar/Desactivar la bomba</span>    
                    <button class="p-5 border border-black shadow" :class="pump_active ? 'bg-green-300' : 'bg-red-300'" x-text="pump_active ? 'Activado' : 'Desactivado'" x-on:click="togglePump">Accionar bomba</button>
                </div>
            </div>
            <form x-on:submit.prevent="handle" class="w-full p-4 bg-gray-200 border border-black">
                <h3 class="font-bold text-sm border-b border-black">Configuracion</h3>
                <div class="grid grid-cols-2 gap-4 mt-2 mb-4">
                    <div class="flex flex-col">
                        <label for="interval">Intervalo de riego</label>
                        <div>
                            <input class="w-16 p-2" x-mask="99:99" placeholder="HH:MM" name="interval" id="interval" x-model="interval">
                            <span>(HH:MM)</span>
                        </div>
                    </div>
                    <div class="flex flex-col">
                        <label for="pump_period">Tiempo de bomba</label>
                        <div>
                            <input class="w-16 p-2" x-mask="99:99" placeholder="HH:MM" name="pump_period" id="pump_period" x-model="pump_period">
                            <span>(MM:SS)</span>
                        </div>
                    </div>
                </div>

                <div>
                    <button type="submit" class="px-3 py-2 border border-black flex items-center justify-center">
                        <svg x-show="loading" class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        Guardar
                    </button>
                </div>
            </form>
        </main> 
    </body>
</html>
    """