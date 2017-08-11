package org.dashnine.preditor;

import sleep.bridges.*;
import sleep.runtime.*;
import sleep.interfaces.*;

import java.util.*;

import de.spieleck.app.cngram.NGramProfiles;

/** Utilities for the Sleep Spellchecker used in AtD */
public class GuessLanguage implements Loadable, Function
{
   private static NGramProfiles profiles = null;
   static
   {
      try
      {
         profiles = new NGramProfiles();
      }
      catch (Exception ex) { ex.printStackTrace(); }
   }

   public String guessLanguage(String text)
   {
      if (text.length() > 1024)
          text = text.substring(0, 1024);

      NGramProfiles.Ranker ranker = profiles.getRanker();
      ranker.account(text);
      NGramProfiles.RankResult result = ranker.getRankResult();
      return result.getName(0);
   }

   public Scalar evaluate(String name, ScriptInstance script, Stack args)
   {
      return SleepUtils.getScalar(guessLanguage(BridgeUtilities.getString(args, "")));
   }

   public void scriptLoaded(ScriptInstance script)
   {
      script.getScriptEnvironment().getEnvironment().put("&guessLanguage", this);
   }
    
   public void scriptUnloaded(ScriptInstance script) 
   {
       
   }
}
