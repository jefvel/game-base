import haxe.Timer;
import elke.Game;
import h2d.Object;

#if js
import io.newgrounds.NG;
import io.newgrounds.objects.Medal;
#end

class Newgrounds {
	public static var instance(get, null) : Newgrounds;

	public var username: String = null;
	public var sessionId : String = null;

	public var isLocal = false;

	final heartbeatTime = 4 * 60 * 1000;
	var heartbeatTimer: Timer = null;

	static final APP_ID = Const.NEWGROUNDS_APP_ID;
	static final ENCRYPTION_KEY_RC4 = Const.NEWGROUNDS_ENCRYPTION_KEY_RC4;

	static var _instance: Newgrounds = null;
	function new() {}

	var failedLogin = false;

	#if debug
	final debug = true;
	#else
	final debug = false;
	#end

	public static function initializeAndLogin(?onSuccess : Void -> Void, ?onFail: Void -> Void) {
		if (_instance != null) {
			if (onSuccess != null) {
				onSuccess();
			}

			return _instance;
		}

		trace("Creating new newgrounds API");
		_instance = new Newgrounds();
		_instance.init(onSuccess, onFail);

		return _instance;
	}

	function onLoginCallback() {
	}

	function init(?onSuccess, ?onFail) {
		#if js
		var onLogin = () -> {
			sessionId = NG.core.sessionId;
			username = NG.core.user.name;

			trace('Logged in as $username with session ID $sessionId');

			sessionId = null;

			loadMedalsAndScoreboards();

			// Start heartbeat
			if (heartbeatTimer != null) {
				heartbeatTimer.stop();
			}

			heartbeatTimer = Timer.delay(heartbeat, heartbeatTime);

			if (onSuccess != null) {
				onSuccess();
			}
		}

		NG.createAndCheckSession(APP_ID, debug, sessionId, (e) -> {
			NG.core.onLogin.remove(onLogin);
			failedLogin = true;
			if (onFail != null) {
				onFail();
			}
		});

		NG.core.initEncryption(ENCRYPTION_KEY_RC4);

		NG.core.onLogin.addOnce(onLogin);

		#else
		isLocal = true;
		if (onSuccess != null) {
			onSuccess();
		}
		#end
	}

	function heartbeat() {
		#if js
		NG.core.calls.gateway.ping().addSuccessHandler(() -> {
			trace("Heartbeat success");
			heartbeatTimer = Timer.delay(heartbeat, heartbeatTime);
		}).addErrorHandler((error) -> {
			trace("Heartbeat failure, trying to reinitiate session");
			init();
		}).send();
		#end
	}

	function loadMedalsAndScoreboards(?onComplete: Void -> Void) {
		#if js
		NG.core.requestMedals(() -> {
			if (onComplete != null) {
				onComplete();
			}
		});
		NG.core.requestScoreBoards(() -> {});
		#end
	}

	public function unlockMedal(medalID: Int) {
		#if js
		if (NG.core.loggedIn) {
			var ngMedal = NG.core.medals.get(medalID);
			if (ngMedal == null) {
				loadMedalsAndScoreboards(() -> {
					var ngMedal = NG.core.medals.get(medalID);
					if (ngMedal != null) {
						if (unlockNgMedal(ngMedal)) {
						}
					}
				});
			} else {
				if (unlockNgMedal(ngMedal)) {
				}
			}
		}
		#end
	}

	public function submitHighscore(scoreboardID: Int, totalScore: Int) {
		#if js
		if (NG.core.loggedIn) {
			var board = NG.core.scoreBoards.get(scoreboardID);
			board.postScore(totalScore);
		}
		#end
	}

	#if js
	function unlockNgMedal(m:Medal) {
		if (m.unlocked) {
			return false;
		}

		#if debug
		m.sendDebugUnlock();
		#else
		m.sendUnlock();
		#end

		return true;
	}
	#end

	public static function get_instance() {
		if (_instance == null) {
			initializeAndLogin();
		}

		return _instance;
	}
}