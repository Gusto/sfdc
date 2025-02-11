import { LightningElement, wire, track, api } from "lwc";
import { refreshApex } from "@salesforce/apex";
import timerPause from "@salesforce/resourceUrl/timerpause";
import timerPlay from "@salesforce/resourceUrl/timerplay";
import updateCaseSessionTime from "@salesforce/apex/ServiceConsoleCaseTimerCtrl.updateCaseSessionTime";
import grabCaseStatus from "@salesforce/apex/ServiceConsoleCaseTimerCtrl.grabCaseStatus";

export default class serviceConsoleCaseTimerCmp extends LightningElement {
	//Static Resources
	timerPauseBtn = timerPause;
	timerPlayBtn = timerPlay;

	//Fields and IDs
	@api recordId;
	@track caseId;

	//Design Attributes
	@api hideCmp = false;
	@api cmpHeader;
	@api hideClock = false;

	//Timer Variables
	@track stime = "00:00:00";
	@track playing = false;
	@track recording = false;
	timeIntervalInstance;
	clocktimer;
	@track ispaused;
	@track tabisclosed;
	@track caseRecord;

	@track record;
	@track error;

	@wire(grabCaseStatus, { idCase: "$recordId" })
	wireCaseStatus(result) {
		this.status = result;
		if (result.data) {
			if (result.data === "In Progress" && this.playing !== true) {
				this.start();
			} else {
				this.stop();
			}

			this.error = undefined;
		} else if (result.error) {
			this.error = result.error;
		}
	}

	@api
	get paused() {
		return this._paused;
	}

	set paused(value) {
		this._paused = value;
		this.ispaused = this._paused;
		this.pauseTimer(this.ispaused);
	}

	@api
	get recordChange() {
		return this._recordChange;
	}

	set recordChange(value) {
		this._recordChange = value;
		refreshApex(this.status);
	}

	@api
	get tabclosed() {
		return this._tabclosed;
	}

	set tabclosed(value) {
		this._tabclosed = value;
		this.tabisclosed = this._tabclosed;
		if (this.tabisclosed) {
			this.disconnectedHandler();
		}
	}

	constructor(params) {
		super(params);
		this.disconnectedHandler = this.disconnectedHandler.bind(this);
		this.pauseTimer = this.pauseTimer.bind(this);
	}

	connectedCallback() {
		window.addEventListener("beforeunload", this.disconnectedHandler);

		if (window.localStorage.getItem("startTimer")) {
			this.setTimer();
		}
	}

	// Function for detecting window navigation/closing
	disconnectedHandler() {
		if (this.stime !== "00:00:00") {
			this.stop();
			updateCaseSessionTime({ idCase: this.recordId, strTimeVal: this.stime })
				.then(() => {})
				.catch((error) => {
					console.log("Error" - error);
				});
		}
	}

	pauseTimer(ontab) {
		switch (ontab) {
			// False means play timer
			case false:
				if (this.stime !== "00:00:00" && this.playing !== true) {
					this.start();
				}
				break;
			// True means pause timer
			case true:
				this.stop();
				break;
			default:
				this.stop();
				break;
		}
	}

	//Pause Timer/Session Method
	btnClick(event) {
		var id = event.target.dataset.id;
		switch (id) {
			case "start":
				this.start();
				break;
			case "stop":
				this.stop();
				break;
			default:
				this.stop();
				break;
		}
	}

	/////////////////HELPER METHODS//////////////////
	start() {
		const startTime = new Date(this.startTimerHandler());

		let that = this;
		this.playing = true;
		this.recording = true;
		this.clocktimer = setInterval(function () {
			const secsDiff = new Date().getTime() - startTime.getTime();
			that.updateStatus(secsDiff);
		}, 100);
	}

	stop() {
		this.playing = false;
		this.recording = false;
		clearInterval(this.clocktimer);
		window.localStorage.removeItem("startTimer");
	}

	updateStatus(secsDiff) {
		this.stime = this.formatMilliseconds(secsDiff);
	}

	//stopwatch stores values as milliseconds
	formatMilliseconds(milliseconds) {
		var h,
			m,
			s = 0;

		h = Math.floor(milliseconds / (60 * 60 * 1000));
		milliseconds = milliseconds % (60 * 60 * 1000);
		m = Math.floor(milliseconds / (60 * 1000));
		milliseconds = milliseconds % (60 * 1000);
		s = Math.floor(milliseconds / 1000);

		return this.pad(h, 2) + ":" + this.pad(m, 2) + ":" + this.pad(s, 2);
	}

	//stopwatch stores values as milliseconds
	getTotalMilliseconds() {
		const list_TimeVal = this.stime.split(":");
		var intHours = parseInt(list_TimeVal[0]);
		var intMinutes = parseInt(list_TimeVal[1]);
		var intSeconds = parseInt(list_TimeVal[2]);
		var intFullTime = (intSeconds + intMinutes * 60 + intHours * 3600) * 1000;

		return intFullTime;
	}

	pad(num, size) {
		var s = "0000" + num;
		return s.substr(s.length - size);
	}

	startTimerHandler() {
		const startTime = new Date() - this.getTotalMilliseconds();
		window.localStorage.setItem("startTimer", startTime);
		return startTime;
	}
	//////////////////////////////////////////////////
}