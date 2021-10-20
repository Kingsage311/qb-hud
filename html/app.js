// MONEY HUD

const moneyHud = Vue.createApp({
    data() {
        return {
            cash: 0,
            bank: 0,
            amount: 0,
            plus: false,
            minus: false,
            showCash: false,
            showBank: false,
            showUpdate: false,
        };
    },
    destroyed() {
        window.removeEventListener("message", this.listener);
    },
    mounted() {
        this.listener = window.addEventListener("message", (event) => {
            switch (event.data.action) {
                case "showconstant":
                    this.showConstant(event.data);
                    break;
                case "update":
                    this.update(event.data);
                    break;
                case "show":
                    this.showAccounts(event.data);
                    break;
            }
        });
    },
    methods: {
        // CONFIGURE YOUR CURRENCY HERE
        // https://www.w3schools.com/tags/ref_language_codes.asp LANGUAGE CODES
        // https://www.w3schools.com/tags/ref_country_codes.asp COUNTRY CODES
        formatMoney(value) {
            const formatter = new Intl.NumberFormat("en-US", {
                style: "currency",
                currency: "USD",
                minimumFractionDigits: 0,
            });
            return formatter.format(value);
        },
        showConstant(data) {
            this.showCash = true;
            this.showBank = true;
            this.cash = data.cash;
            this.bank = data.bank;
        },
        update(data) {
            this.showUpdate = true;
            this.amount = data.amount;
            this.bank = data.bank;
            this.cash = data.cash;
            this.minus = data.minus;
            this.plus = data.plus;
            if (data.type === "cash") {
                if (data.minus) {
                    this.showCash = true;
                    this.minus = true;
                    setTimeout(() => (this.showUpdate = false), 1000);
                    setTimeout(() => (this.showCash = false), 2000);
                } else {
                    this.showCash = true;
                    this.plus = true;
                    setTimeout(() => (this.showUpdate = false), 1000);
                    setTimeout(() => (this.showCash = false), 2000);
                }
            }
            if (data.type === "bank") {
                if (data.minus) {
                    this.showBank = true;
                    this.minus = true;
                    setTimeout(() => (this.showUpdate = false), 1000);
                    setTimeout(() => (this.showBank = false), 2000);
                } else {
                    this.showBank = true;
                    this.plus = true;
                    setTimeout(() => (this.showUpdate = false), 1000);
                    setTimeout(() => (this.showBank = false), 2000);
                }
            }
        },
        showAccounts(data) {
            if (data.type === "cash" && !this.showCash) {
                this.showCash = true;
                this.cash = data.cash;
                setTimeout(() => (this.showCash = false), 3500);
            } else if (data.type === "bank" && !this.showBank) {
                this.showBank = true;
                this.bank = data.bank;
                setTimeout(() => (this.showBank = false), 3500);
            }
        },
    },
}).mount("#money-container");

// PLAYER HUD

const playerHud = {
    data() {
        return {
            id: 0,
            voice: 0,
            radio: 0,
            health: 0,
            armor: 0,
            hunger: 0,
            thirst: 0,
            stress: 0,
            oxygen: 0,
            nos: 0,
            seatbelt: 0,
            fuel: 0,
            show: false,
            showID: true,
            talking: false,
            showVoice: true,
            showHealth: true,
            showArmor: true,
            showHunger: true,
            showBleed: true,
            showThirst: true,
            showStress: true,
            showOxygen: true,
            showNos: true,
            showBelt: true,
            voiceIcon: "fas fa-microphone",
            talkingColor: "#ffffff",
            seatbeltColor: "",
            seatbeltIcon: "fas fa-user"
        };
    },
    destroyed() {
        window.removeEventListener("message", this.listener);
    },
    mounted() {
        this.listener = window.addEventListener("message", (event) => {
            if (event.data.action === "hudtick") {
                this.hudTick(event.data);
            }
        });
    },
    methods: {
        hudTick(data) {
            this.show = data.show;
            this.health = data.health;
            this.id = data.id;
            this.armor = data.armor;
            this.hunger = data.hunger;
            this.thirst = data.thirst;
            this.bleed = data.bleed;
            this.stress = data.stress;
            this.oxygen = data.oxygen;
            this.nos = data.nos;
            this.seatbelt = data.seatbelt;
            this.fuel = data.fuel;
            this.speed = data.speed;
            this.voice = data.voice;
            this.talking = data.talking;
            this.radio = data.radio;
            if (data.talking) {
                this.talkingColor = "#ae47ff";
            } else {
                this.talkingColor = "#ffffff";
            }
            if (data.health >= 100) {
                this.showHealth = true;
            } else {
                this.showHealth = true;
            }
            if (data.armor <= 0) {
                this.showArmor = false;
            } else {
                this.showArmor = true;
            }
            if (data.hunger >= 100) {
                this.showHunger = true;
            } else {
                this.showHunger = true;
            }
            if (data.thirst >= 100) {
                this.showThirst = true;
            } else {
                this.showThirst = true;
            }
            if (data.bleed <= 0) {
                this.showBleed = false;
            } else {
                this.showBleed = true;
            }
            if (data.stress <= 0) {
                this.showStress = false;
            } else {
                this.showStress = true;
            }
            if (data.oxygen <= 0) {
                this.showOxygen = false;
            } else {
                this.showOxygen = true;
            }
            if (data.nos === 0 || data.nos === undefined) {
                this.showNos = false;
            } else {
                this.showNos = true;
            }
            if (data.seatbelt === true) {
                this.showBelt = true;
                this.seatbeltIcon = 'fas fa-user-slash';
                this.seatbeltColor = "#00b95d";
            } else {
                this.showBelt = true;
                this.seatbeltIcon = 'fas fa-user';
                this.seatbeltColor = "#f41a12";
            }
            if (data.seatbelt === 0) {
                this.showBelt = false;
            }
            if (data.radio != 0 && data.radio != undefined) {
                this.voiceIcon = 'fas fa-headset';
            } else if (data.radio == 0 || data.radio == undefined) {
                this.voiceIcon = 'fas fa-microphone';
            }
        },
    },
};
const app = Vue.createApp(playerHud);
app.use(Quasar);
app.mount("#ui-container");

// VEHICLE HUD

const vehHud = {
    data() {
        return {
            show: false,
            fuel: 0,
            speed: 0,
            street1: "",
            street2: "",
            direction: "",
        };
    },
    destroyed() {
        window.removeEventListener("message", this.listener);
    },
    mounted() {
        this.listener = window.addEventListener("message", (event) => {
            if (event.data.action === "car") {
                this.vehicleHud(event.data);
            }
        });
    },
    methods: {
        vehicleHud(data) {
            this.show = data.show;
            this.speed = data.speed;
            this.direction = data.direction;
            this.street1 = data.street1;
            this.street2 = data.street2;
            this.fuel = data.fuel;
            if (data.isPaused === 1) {
                this.show = false;
            }
        },
    },
};
const app2 = Vue.createApp(vehHud);
app2.use(Quasar);
app2.mount("#veh-container");
