package elke.things;

import hxd.Save;
import haxe.Timer;

#if js
import io.newgrounds.NGLite;
#end

typedef HighScorePost = {
	name: String,
	scoreRaw: Int,
	score: String,
}

private class NewgroundsData {
	public var failedMedalUnlocks: Array<Int> = [];
	public var failedHighscorePosts: Array<{ boardID: Int, score: Int }> = [];

	public function new() {
		failedMedalUnlocks = [];
		failedHighscorePosts = [];
	}
}

/**
 * Simple class for managing newgrounds leaderboards and medals
 */
class Newgrounds {
	public static var instance(get, null) : Newgrounds;

	public var username: String = null;
	public var sessionId : String = null;
	public var signedIn = false;

	public var isLocal = false;

	final heartbeatTime = 3 * 60 * 1000;
	var heartbeatTimer: Timer = null;

	static final APP_ID = Const.NEWGROUNDS_APP_ID;
	static final ENCRYPTION_KEY_RC4 = Const.NEWGROUNDS_ENCRYPTION_KEY_RC4;

	static var _instance: Newgrounds = null;

	public var hasFailedCalls(get, null) = false;
	function get_hasFailedCalls() {
		var d = getFailedCalls();
		return d.failedHighscorePosts.length > 0 || d.failedMedalUnlocks.length > 0;
	}

	function new() {}

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
		try {
			_instance = new Newgrounds();
			_instance.init(onSuccess, onFail);
		} catch (e) {
			trace(e);
		}

		return _instance;
	}

	public function signOut() {
		signedIn = false;
		#if js
		NGLite.core.calls.app.endSession();
		#end
	}

	function init(?onSuccess, ?onFail) {
		#if js
		var onLogin = () -> {
			signedIn = true;
			sessionId = NGLite.getSessionId();

			trace('Logged in as $username with session ID $sessionId');

			// Start heartbeat
			if (heartbeatTimer != null) {
				heartbeatTimer.stop();
			}

			checkFailedMedalsAndUnlocks();

			loadMedalsAndScoreboards(() -> {
				if (onSuccess != null) {
					onSuccess();
				}
			});

			heartbeatTimer = Timer.delay(heartbeat, heartbeatTime);
		}

		var curSessionId = NGLite.getSessionId();
		if (curSessionId == null || curSessionId == "") {
			if (onSuccess != null) {
				onSuccess();
			}
			return;
		}

		NGLite.create(APP_ID, NGLite.getSessionId(), (e) -> {
			if (onFail != null) {
				onFail();
			}
		});

		NGLite.core.initEncryption(ENCRYPTION_KEY_RC4);

		NGLite.core.calls.app.checkSession()
		.addDataHandler(data -> {
			this.username = data.result.data.session.user.name;
			onLogin();
		})
		.addErrorHandler(e -> {
			if (onFail != null) onFail();
		})
		.send();

		#else
		isLocal = true;
		if (onSuccess != null) {
			onSuccess();
		}
		#end
	}

	final ngDataSave = '${Const.SAVE_NAMESPACE}_ng';
	inline function getFailedCalls() {
		return Save.load(new NewgroundsData(), ngDataSave, !debug);
	}
	inline function saveFailedCalls(d: NewgroundsData) {
		Save.save(d, ngDataSave, !debug);
	}

	function checkFailedMedalsAndUnlocks() {
		#if js
		var data = getFailedCalls();
		Save.delete(ngDataSave);

		if (data.failedHighscorePosts != null) {
			var highScores = data.failedHighscorePosts;
			for (d in highScores) {
				submitHighscore(d.boardID, d.score);
			}
		}
		
		if (data.failedMedalUnlocks != null) {
			for (m in data.failedMedalUnlocks) {
				unlockMedal(m);
			}
		}
		#end
	}

	public function getTop10Scoreboard(boardID: Int, onComplete: Array<HighScorePost> -> Void, user: String = null) {
		#if js
		if (!signedIn) {
			onComplete([]);
			return;
		}

		NGLite.core.calls.scoreBoard
		.getScores(boardID, 10, 0, ALL, false, null, user)
		.addDataHandler(data -> {
			var res = data.result.data.scores.map((s) -> ({
				name: s.user.name,
				score: s.formattedValue,
				scoreRaw: s.value,
			}));
			onComplete(res);
		})
		.addErrorHandler(error -> {
			onComplete([]);
		})
		.send();

		#else
		onComplete([]);
		#end
	}

	public function heartbeat() {
		#if js
		if (heartbeatTimer != null) {
			heartbeatTimer.stop();
		}

		NGLite.core.calls.gateway.ping().addSuccessHandler(() -> {
			trace("Heartbeat success");
			heartbeatTimer = Timer.delay(heartbeat, heartbeatTime);
		}).addErrorHandler((error) -> {
			trace("Heartbeat failure, session invalid");
			signedIn = false;
		}).send();
		#end
	}

	public var unlockedMedals: Map<Int, Bool> = new Map();
	function loadMedalsAndScoreboards(?onComplete: Void -> Void) {
		#if js
		if (!signedIn) {
			if (onComplete != null) {
				onComplete();
			}
			return;
		}

		var medalsPromise = new js.lib.Promise((resolve, reject) -> {
			NGLite.core.calls.medal.getList()
			.addDataHandler(h -> {
				for (m in h.result.data.medals) {
					unlockedMedals[m.id] = m.unlocked;
				}
				resolve(true);
			})
			.addErrorHandler(e -> {
				reject(e);
			})
			.send();
		});

		js.lib.Promise.all([
			medalsPromise,
			//boardsPromise,
		]).then(res -> {
			if (onComplete != null) {
				onComplete();
			}
		}, err -> {
			if (onComplete != null) {
				onComplete();
			}
		});
		#end
	}

	public function unlockMedal(medalID: Int) {
		#if js
		if (!signedIn) {
			return;
		}

		if (unlockedMedals.exists(medalID) && unlockedMedals[medalID]) {
			return;
		}

		var posted = false;
		function failedPosting() {
			if (posted) {
				return;
			}

			posted = true;

			var d = getFailedCalls();
			d.failedMedalUnlocks.push(medalID);
			saveFailedCalls(d);
			trace(d);
		}

		NGLite.core.calls.medal.unlock(medalID)
		.addSuccessHandler(() -> {
			unlockedMedals[medalID] = true;
		})
		.addDataHandler(r -> {
			if (!r.result.success || !r.result.data.success) {
				failedPosting();
			}
		})
		.addErrorHandler(e -> {
			failedPosting();
		})
		.send();
		#end
	}

	public function submitTimeHighscore(scoreboardID: Int, seconds: Float) {
		var timeMillisecs = Std.int(seconds * 1000);
		submitHighscore(scoreboardID, timeMillisecs);
	}

	public function submitHighscore(scoreboardID: Int, totalScore: Int) {
		#if js
		if (!signedIn) {
			return;
		}

		var posted = false;
		function failedPosting(){ 
			if (posted) {
				return;
			}
			posted = true;

			var d = getFailedCalls();
			d.failedHighscorePosts.push({
				boardID: scoreboardID,
				score: totalScore,
			});

			saveFailedCalls(d);
		}

		NGLite.core.calls.scoreBoard
		.postScore(scoreboardID, totalScore)
		.addErrorHandler(e -> {
			failedPosting();
		})
		.addDataHandler(r -> {
			if (!r.result.success || !r.result.data.success) {
				failedPosting();
			}
		})
		.send();
		#end
	}

	public static function get_instance() {
		if (_instance == null) {
			initializeAndLogin();
		}

		return _instance;
	}
}