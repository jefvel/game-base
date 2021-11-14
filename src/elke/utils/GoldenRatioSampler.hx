package elke.utils;

/**
 * a sampler for getting unique samples uniformly between 0-1
 * gotten from https://blog.bruce-hill.com/6-useful-snippets#Golden-Ratio-Sampling
 */
class GoldenRatioSampler {
	var i = 0;
	final goldenRatio = (Math.sqrt(5) + 1) / 2.;
	public function new() {
	}
	public function nextSample() {
		i ++;
		return (i * goldenRatio) % 1;
	}
}