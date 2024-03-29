package elke.sound;

import hxd.snd.SoundGroup;
import hxd.snd.Channel;
import hxd.res.Sound;
import hxd.snd.ChannelGroup;

class Sounds {
	public var sfxChannel:ChannelGroup;
	public var musicChannel:ChannelGroup;

	public var sfxVolume(get, set):Float;
	public var musicVolume(get, set):Float;

	var currentMusic:Channel;

	function get_sfxVolume()
		return sfxChannel.volume;

	function set_sfxVolume(volume:Float)
		return sfxChannel.volume = volume;

	function get_musicVolume()
		return musicChannel.volume;

	function set_musicVolume(volume:Float)
		return musicChannel.volume = volume;

	public function new() {
		sfxChannel = new ChannelGroup("sfx");
		musicChannel = new ChannelGroup("music");
	}

	public function playSfx(snd:Sound, volume = 0.5, loop = false) {
		return snd.play(loop, volume, sfxChannel);
	}

	public function playMusic(music:Sound, volume = .5, loop = true) {
		currentMusic = music.play(loop, volume, musicChannel);
		return currentMusic;
	}

	public function stopMusic(fadeoutTime = 0.0) {
		if (currentMusic != null) {
			if (fadeoutTime > 0) {
				currentMusic.fadeTo(0, fadeoutTime, () -> currentMusic.stop());
			} else {
				currentMusic.stop();
			}
			currentMusic = null;
		}
	}

	/**
	 * plays wobbly sound effect with random pitch
	 * @param snd
	 * @param volume = 0.3
	 */
	public function playWobble(snd:hxd.res.Sound, volume = 0.3, wobbleAmount = 0.1, loop = false) {
		var sound = snd.play(loop, volume, sfxChannel);
		sound.addEffect(new hxd.snd.effect.Pitch(1 - wobbleAmount + Math.random() * (wobbleAmount * 2)));
		return sound;
	}
}
