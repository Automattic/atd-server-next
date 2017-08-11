package org.dashnine.preditor;

import java.io.*;
import java.util.*;
import java.util.zip.*;

/** This class holds the (minified) AtD language model */
public class LanguageModelSmall extends LanguageModel implements Serializable
{
   protected ZipFile entries;

   private static long lowMemoryThreshold = 256 * 1024 * 1024;

   protected class CacheMap extends LinkedHashMap 
   {
       protected boolean removeEldestEntry(Map.Entry eldest) 
       {
          long memory = Runtime.getRuntime().freeMemory() + (Runtime.getRuntime().maxMemory() - Runtime.getRuntime().totalMemory());
          return (size() > 16384 || memory < lowMemoryThreshold);
       }
   }

   /* read a string value from the specified map... adds the string if it doesn't exist */
   protected Value getStringValue(Map map, String word, boolean makeAsNecessary)
   {
      Object sid = getStringId(word, false);

      if (sid != null)
      {
         synchronized (this)   
         {
            Value val = (Value)map.get(sid);
            if (val == null && map == model)
            {
               try 
               {
                  int sid_i = ((Integer)sid).intValue();
	
                  ZipEntry entry = entries.getEntry((sid_i % 512) + "/" + sid_i);
                  if (entry != null)
                  {
                     ObjectInputStream stream = new ObjectInputStream(entries.getInputStream(entry));
                     val = (Value)stream.readObject();
                     map.put(sid, val);
                  }
               }
               catch (Exception ex) 
               {
                  System.err.println("Could not load: " + word + "(" + sid + ")");
                  ex.printStackTrace();
               }
            }
            return val;
         }
      }

      return null;
   }

   public LanguageModelSmall(Map _string_pool, long _count, File entries_file)
   {
      string_pool = _string_pool;
      count = _count;
      model = new CacheMap();
      try 
      {
         entries = new ZipFile(entries_file);      
      }
      catch (Exception ex) 
      {
         System.err.println("Could not load zipfile: " + entries_file);
         ex.printStackTrace();
      }
   }
}
