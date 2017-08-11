package org.dashnine.preditor;

import java.io.Serializable;
import java.util.*;

/** This class holds the AtD language model */
public class LanguageModel implements Serializable
{
   protected long count;
   protected int string_count = 1;
   protected Map string_pool;
   protected Map model;

   /*
    * these functions make it possible to harvest a low-memory language model from this
    * large one.
    */
   public Map getStringPool() 
   {
      return string_pool;
   }

   public Map getLanguageModel() 
   {
      return model;
   }
   
   /* harvest a dictionary from the language model */
   public List harvest(int threshold)
   {
      List results = new LinkedList();

      Iterator i = string_pool.entrySet().iterator();
      while (i.hasNext())
      {
         Map.Entry temp = (Map.Entry)i.next();
         String word = temp.getKey().toString();
         Object key  = temp.getValue();
         Value  val  = (Value)model.get(key);
         if (val != null && val.count >= threshold)
         {
            results.add(word);
         }  
      }

      return results;
   }

   protected static final class Value implements Serializable
   {
      public Map next = null;
      public int count = 0;
   }

   /* we associate an integer object with each string to save space in the language model,
      normally this would be such a trivial savings but we're dealing with so much data */
   protected Object getStringId(String word, boolean makeAsNecessary)
   {
      Object sid = string_pool.get(word);

      if (sid != null)
      {
         return sid;
      }
      else if (makeAsNecessary)
      {
         sid = new Integer(string_count);
         string_count++;
         string_pool.put(word, sid);

         return sid;
      }

      return null;
   }

   /* read a string value from the specified map... adds the string if it doesn't exist */
   protected Value getStringValue(Map map, String word, boolean makeAsNecessary)
   {
      Object sid = getStringId(word, makeAsNecessary);
      if (sid != null)
      {
         Value val = (Value)map.get(sid);
         if (val == null && makeAsNecessary)
         {
            val = new Value();
            map.put(sid, val);
         }
         return val;
      }

      return null;
   }

   public LanguageModel()
   {
      string_pool = new HashMap();
      model = new HashMap();
   }

   public void addUnigram(String word)
   {
      synchronized (this)
      {
         Value val = getStringValue(model, word, true);
         val.count += 1;

         if (!word.equals("0BEGIN.0") && !word.equals("0END.0"))
             count += 1;
      }
   }

   public void addBigram(String worda, String wordb)
   {
      synchronized (this)
      {
         Value first  = getStringValue(model, worda, true);
         if (first.next == null)
            first.next = new HashMap();

         Value second = getStringValue(first.next, wordb, true);
         second.count += 1;
      }
   }

   public void addTrigram(String worda, String wordb, String wordc)
   {
      synchronized (this)
      {
          Value first  = getStringValue(model, worda, true);
          if (first.next == null)
             first.next = new HashMap();

          Value second = getStringValue(first.next, wordb, true);
          if (second.next == null)
             second.next = new HashMap();

          Value third  = getStringValue(second.next, wordc, true);
          third.count += 1;
      }
   }

   /* return |word| */
   public int count(String word)
   {
      Value value = getStringValue(model, word, false);

      if (value == null)
         return 0;

      return value.count;
   }

   /* return P(word) */
   public double Pword(String word)
   {
      if (word.indexOf(' ') == -1)
      {
         Value value = getStringValue(model, word, false);

         if (value == null)
            return 0.0;

         return (double)value.count / (double)count;
      }
      else
      {
         Value v_prev = getStringValue(model, word.substring(0, word.indexOf(' ')), false);
         
         if (v_prev == null || v_prev.next == null || v_prev.count == 0)
            return 0.0;

         Value v_word = getStringValue(v_prev.next, word.substring(word.indexOf(' ') + 1), false);

         if (v_word == null)
            return 0.0;

         return (double)v_word.count / (double)count;
      }
   }

   /* return P(word | previous) */
   public double Pbigram1(String previous, String word)
   {
      Value v_prev = getStringValue(model, previous, false);
      if (v_prev == null || v_prev.next == null || v_prev.count == 0)
         return 0.0;

      if (word.indexOf(' ') == -1)
      {
         Value v_word = getStringValue(v_prev.next, word, false);
         if (v_word == null)
             return 0.0;

         return (double)v_word.count / (double)v_prev.count;
      }
      else
      {
         String word1, word2;
         word1 = word.substring(0, word.indexOf(' '));
         word2 = word.substring(word.indexOf(' ') + 1);

         Value v_word = getStringValue(v_prev.next, word1, false);
         if (v_word == null)
             return 0.0;

         return ((double)v_word.count / (double)v_prev.count) * Pbigram1(word1, word2);
      }
   }

   /* return P(word | next) */
   public double Pbigram2(String word, String next)
   {
      if (word.indexOf(' ') == -1)
      {
         double pNext = Pword(next);
         if (pNext == 0.0)
         {
            return Pword(word);
         }
         else
         {
            return (Pbigram1(word, next) * Pword(word)) / pNext;
         }
      }
      else
      {
         String word1, word2;
         word1 = word.substring(0, word.indexOf(' '));
         word2 = word.substring(word.indexOf(' ') + 1);

         return Pbigram2(word2, next) * Pbigram1(word1, word2);
      }
   }

   /* P(a|b,c) */
   public double Ptrigram2(String a, String b, String c)
   {
      double Pnext = Pword(b + " " + c);
      if (Pnext == 0.0) 
         return 0.0;

      return Ptrigram3(a, b, c) * Pword(a) / Pnext;
   }

   /* P(a, b| c) */
   public double Ptrigram3(String a, String b, String c)
   {
      /* calculate count(a, b, c) */

      Value v_first  = getStringValue(model, a, false);
      if (v_first == null || v_first.next == null)
         return 0.0;

      Value v_second = getStringValue(v_first.next, b, false);
      if (v_second == null || v_second.next == null || v_second.count == 0)
         return 0.0;

      Value v_third  = getStringValue(v_second.next, c, false);
      if (v_third == null)
         return 0.0;

      /* return count(a, b, c) / count(a) */

      return (double)v_third.count / (double)v_first.count;
   }

   /* check if these two words have a trigram or not */
   public boolean hasTrigram(String a, String b)
   {
      Value v_first  = getStringValue(model, a, false);
      if (v_first == null || v_first.next == null)
         return false;

      Value v_second = getStringValue(v_first.next, b, false);
      if (v_second == null || v_second.next == null || v_second.count == 0)
         return false;

      return true;
   }

   /* return P(c | a,b) */
   public double Ptrigram(String a, String b, String c)
   {
      Value v_first  = getStringValue(model, a, false);
      if (v_first == null || v_first.next == null)
         return 0.0;

      Value v_second = getStringValue(v_first.next, b, false);
      if (v_second == null || v_second.next == null || v_second.count == 0)
         return 0.0;

      Value v_third  = getStringValue(v_second.next, c, false);
      if (v_third == null)
         return 0.0;

      return (double)v_third.count / (double)v_second.count;
   }
}
