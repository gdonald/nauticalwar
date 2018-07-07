package com.nauticalwar.shared;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.SoundPool;
import android.util.SparseIntArray;

class SoundManager
{
  private SoundPool soundPool;
  private SparseIntArray soundPoolMap;
  private Context context;

  public SoundManager()
  {
  }

  public void addSound(final int index, final int id)
  {
    soundPoolMap.put(index, soundPool.load(context, id, 1));
  }

  public void initSounds(final Context theContext)
  {
    context = theContext;

    AudioAttributes attributes = new AudioAttributes.Builder().setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION).build();
    soundPool = new SoundPool.Builder().setAudioAttributes(attributes).setMaxStreams(10).build();
    soundPoolMap = new SparseIntArray();
  }

  public void playSound(final int index)
  {
    soundPool.play(soundPoolMap.get(index), 0.99f, 0.99f, 1, 0, 0.99f);
  }
}
