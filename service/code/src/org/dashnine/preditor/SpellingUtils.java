package org.dashnine.preditor;

import sleep.runtime.*;
import sleep.bridges.*;
import sleep.interfaces.*;

import java.util.regex.*;
import java.util.*;

/** Utilities for the Sleep Spellchecker used in AtD */
public class SpellingUtils implements Loadable, Function
{
   private static Map patterns = Collections.synchronizedMap(new HashMap());
   public static boolean noWordSeparation = false;

   private static Pattern getPattern(String pattern)
   {
       Pattern temp = (Pattern)patterns.get(pattern);

       if (temp != null)
       {
          return temp;
       }
       else
       {
          temp = Pattern.compile(pattern);
          patterns.put(pattern, temp);

          return temp;
       }
   }

   public Scalar transition(ScalarHash state, ScalarArray path, int count)
   {
      try {
      /* increment the depth count */

      count++;

      if (path.size() > 0)
      {
         ScalarArray items = path.getAt(0).getArray();
//         System.err.println("  Path: " + SleepUtils.describe(SleepUtils.getScalar(path)));
//         System.err.println("           Items: " + SleepUtils.describe(SleepUtils.getScalar(items)));
         String word = items.getAt(0).toString();
         String tag  = items.getAt(1).toString();

         Iterator transitions = ((Scalar)state.getData().get("transitions")).getArray().scalarIterator();
         while (transitions.hasNext())
         {
             ScalarHash value = ((Scalar)transitions.next()).getHash();
             Matcher criteria = getPattern(value.getData().get("criteria").toString()).matcher(word);
             Matcher tagc     = getPattern(value.getData().get("tagc").toString()).matcher(tag);

             if (criteria.matches() && tagc.matches())
             {
//                System.err.println("    Transition: " + SleepUtils.describe( SleepUtils.getScalar(path.sublist(1, path.size()))      ));

                Scalar match = transition(value, path.sublist(1, path.size()), count);
                if (match != null)
                {
                   return match;
                }
             }
         }
      }

      if (state.getData().get("result") != null)
      {
         Scalar temp    = (Scalar)state.getData().get("result");

         if (!SleepUtils.isEmptyScalar(temp))
         {
            Scalar results = SleepUtils.getArrayScalar();         
            results.getArray().push(SleepUtils.getHashScalar(temp.getHash()));
            results.getArray().push(SleepUtils.getScalar(count - 1));
            results.getArray().push(SleepUtils.getHashScalar(state));

//            System.err.println("Results: " + SleepUtils.describe(results));     

            return results;
         }
      }
      } catch (Exception ex) { ex.printStackTrace(); }
      return null;
   }

   public String soundex(String text)
   {
      StringBuffer buffer = new StringBuffer();
      char[] chars = text.toUpperCase().toCharArray();

      buffer.append(chars[0]);
   
      for (int x = 1; x < chars.length; x++)
      {
         switch (chars[x])
         {
            case 'B': 
            case 'P': 
            case 'F': 
            case 'V': 
               buffer.append('1');
               break;
            case 'C':
            case 'S':
            case 'G':
            case 'J':
            case 'K':
            case 'Q':
            case 'X':
            case 'Z':
               buffer.append('2');
               break;
            case 'D':
            case 'T':
               buffer.append('3');
               break;
            case 'L':
               buffer.append('4');
               break;
            case 'M':
            case 'N':
               buffer.append('5');
               break;
            case 'R':
               buffer.append('6');
               break;
            default:
         }
      }

      buffer.append("000");
      return buffer.toString().substring(0, 4);
   }

   public List filterByDictionary(LanguageModel model, String word, Map dictionary)
   {
      List results;

      long start = System.currentTimeMillis();

      results = new LinkedList();

      int high, low;
      high = word.length() + 2;
      low  = word.length() - 2;

      int count = 0;

      Iterator i = dictionary.entrySet().iterator();
      while (i.hasNext())
      {
         Map.Entry temp = (Map.Entry)i.next();

         if (temp.getValue().toString().length() == 0)
         {
            i.remove();
         }
         else
         {
            String key  = temp.getKey().toString();
            if (key.length() >= low && key.length() <= high)
            {
               count++;

               int distance = editDistance(word, key);

               /* consider words of edit distance 2, or edit distance 3 with a soundex match within one on the mispelled word.
                  should note that I'm not adjusting the high/low numbers as this could make this computation really painful */
               if (distance <= 2) // || (distance == 3 && editDistance(soundex(word),soundex(key)) == 1))
               {
                  results.add(key);
               }  
            }         
         } 
      }

      /* add any legitimate sounding split of the misspelled words */
      addSuggestionsWithSpaces(model, results, dictionary, word);

//      start = System.currentTimeMillis() - start;
//      System.err.println("[filter]: '" + word + "' took " + start + "ms for " + results.size() + " entries");
//      System.err.println("           " + results);

      return results;
   }

   public void addSuggestionsWithSpaces(LanguageModel model, Object results, Map dictionary, String text)
   {
      if (noWordSeparation)
         return;

      for (int x = 1; x < text.length(); x++)
      {
         String word1 = text.substring(0, x);
         String word2 = text.substring(x);

         if (dictionary.containsKey(word1) && dictionary.containsKey(word2))
         {
            if (model.Pword(word1 + " " + word2) > 0.0)
            {
               if (results instanceof Set)
               {
                  ((Set)results).add(word1 + " " + word2);
               }
               else if (results instanceof List) 
               {
                  ((List)results).add(word1 + " " + word2);
               }
            }
         }
      }
   }

   public Set editst(LanguageModel model, Map dictionary, Map trie, String text)
   {
      long start = System.currentTimeMillis();

      /* find all words within an edit distance of two */
     
      Set results = new HashSet();
      editsTrie(trie, text, results, 2);

      /* add any legitimate sounding split of the misspelled words */
      addSuggestionsWithSpaces(model, results, dictionary, text);

      /* no results, still? wow--they can't spel! Try going out more edits (up to 3) */

      if (results.size() == 0)
         editsTrie(trie, text, results, 3);

      return results;
   }

   public void editsTrie(Map trieRoot, String text, Set results, int edits)
   {
      /* have we gone to the end of this text path, if so, evaluate if we're within our edits and add to our results path */

      if (text.length() == 0 && edits >= 0 && !trieRoot.get("word").toString().equals(""))
      {
          results.add(trieRoot.get("word").toString());
      }      

      if (edits >= 1)
      {
          /* deletion: remove the current letter, evaluate from the current branch */

          editsTrie(trieRoot, text.length() > 1 ? text.substring(1) : "", results, edits - 1);         

          Iterator i = ((Scalar)trieRoot.get("branches")).getHash().getData().values().iterator();
          while (i.hasNext())
          {
             Map branch = ((Scalar)i.next()).getHash().getData();

             /* insertion: pass the current word, no changes, to each branch; simulates appending each letter to this position */

             editsTrie(branch, text, results, edits - 1);

             /* substitution: pass the current word, sans first letter, to each branch for processing */

             editsTrie(branch, text.length() > 1 ? text.substring(1) : "", results, edits - 1);
          }

          /* transposition (swap the first and second letters) */

          if (text.length() > 2)
          {
             editsTrie(trieRoot, text.charAt(1) + "" + text.charAt(0) + text.substring(2), results, edits - 1);
          }
          else if (text.length() == 2)
          {
             editsTrie(trieRoot, text.charAt(1) + "" + text.charAt(0) + "", results, edits - 1);
          }
      }

      /* move on to the next letter.  as if no edits have happened */

      if (text.length() >= 1)
      {
         Map branches   = ((Scalar)trieRoot.get("branches"))  .getHash().getData();
         Scalar temp    = (Scalar)branches.get( text.charAt(0) + "" );

         if (temp != null)
         {
            Map nextBranch = temp.getHash().getData();
            editsTrie(nextBranch, text.length() > 1 ? text.substring(1) : "", results, edits); 
         }
      }
   }

   public List edits2(String text)
   {
      List results = new LinkedList();

      Iterator i = edits(text).iterator();
      while (i.hasNext())
      {
         String word = i.next().toString();
         results.add(word);
         
         Iterator j = edits(word).iterator();
         while (j.hasNext())
         {
            results.add(j.next().toString());
         }
      }

      return results;
   }

   public List edits(String text)
   {
      List results = new LinkedList();

      for (int i = 0; i < text.length(); i++) 
         results.add(text.substring(0, i) + text.substring(i+1));

      for (int i = 0; i < (text.length() - 1); i++) 
         results.add(text.substring(0, i) + text.substring(i+1, i+2) + text.substring(i, i+1) + text.substring(i+2));

      for (int i = 0; i < text.length(); i++)
      {
         for (char c = 'a'; c <= 'z'; c++)
         {
            results.add(text.substring(0, i) + String.valueOf(c) + text.substring(i + 1));
         }
      }

      for (int i = 0; i <= text.length(); i++)
      {
         for (char c = 'a'; c <= 'z'; c++)
         {
            results.add(text.substring(0, i) + String.valueOf(c) + text.substring(i));
         }
      }

      for (char c = 'A'; c <= 'Z'; c++)
      {
         results.add(c + text.substring(1));
      }

      return results;
   }

   public int min(int a, int b)
   {
      return a > b ? b : a;
   }

   public int min(int a, int b, int c)
   {
      int temp = min(a, b);
      return temp > c ? c : temp;
   }

   public int scoreDifference(char s, char t)
   {
      switch (s) 
      {
         case 'î':
         case 'í': 
         case 'ï':
         case 'ì':
            return t == 'i' ? 0 : 1;
         case 'i':
            return t == 'í' || t == 'î' || t == 'ï' || t == 'ì' ? 0 : 1;
         case 'á':
         case 'à':
         case 'ä':
         case 'â':
            return t == 'a' ? 0 : 1;
         case 'a':
            return t == 'á' || t == 'à' || t == 'ä' || t == 'â' ? 0 : 1;
         case 'é':
         case 'è':
         case 'ê':
         case 'ë':
            return t == 'e' ? 0 : 1;
         case 'e':
            return t == 'é' || t == 'ê' || t == 'ë' || t == 'è' ? 0 : 1;
         case 'ñ':
            return t == 'n' ? 0 : 1;
         case 'n':
            return t == 'ñ' ? 0 : 1;
         case 'ç':
            return t == 'c' ? 0 : 1;
         case 'c':
            return t == 'ç' ? 0 : 1;
         case 'ú':
         case 'ù':
         case 'û':
         case 'ü':
            return t == 'u' ? 0 : 1;
         case 'u':
            return t == 'ú' || t == 'û' || t == 'ù' || t == 'ü' ? 0 : 1;
         case 'ö':
         case 'ò':
         case 'ó':
         case 'ô':
           return t == 'o' ? 0 : 1;
         case 'o':
           return t == 'ö' || t == 'ò' || t == 'ó' || t == 'ô' ? 0 : 1;
      }
      return 1;
   }

   public int editDistance(String s, String t)
   {
      int m = s.length();
      int n = t.length();
      int results[][] = new int[m + 1][n + 1];

      int a, b, c;

      for (int i = 0; i <= m; i++)
      {
         results[i][0] = i;
      }
  
      for (int j = 0; j <= n; j++)
      {
         results[0][j] = j;
      }

      for (int i = 1; i <= m; i++)
      {
         for (int j = 1; j <= n; j++)
         {
            int cost = s.charAt(i - 1) == t.charAt(j - 1) ? 0 : 1;

            results[i][j] = min(results[i - 1][j] + 1,
                                results[i][j - 1] + 1,
                                results[i - 1][j - 1] + cost);
            if (i > 1 && j > 1 && s.charAt(i - 1) == t.charAt(j - 2) && s.charAt(i - 2) == t.charAt(j - 1))
            {
                results[i][j] = min(results[i][j], results[i - 2][j - 2] + cost);
            }
         }
      }

      return results[m][n];
   }
   
   protected Scalar toScalarArray(List list)
   {
      Scalar temp = SleepUtils.getArrayScalar();
      Iterator i = list.iterator();
      while (i.hasNext())
      {
         temp.getArray().push(SleepUtils.getScalar(  i.next().toString()  ));
      }
      return temp;
   }

   protected void puts(Scalar data, String key, Scalar value)
   {
      Scalar temp = data.getHash().getAt(SleepUtils.getScalar(key));
      temp.setValue(value);
   }

   protected Scalar processLayer(ScalarHash outside, ScalarHash inside)
   {
      Scalar results = SleepUtils.getHashScalar();

      Iterator i = outside.getData().entrySet().iterator();
      while (i.hasNext())
      {
         Map.Entry temp = (Map.Entry)i.next();
        
         double sum = 0.0;
         String     id      = temp.getKey().toString();
         ScalarHash weights = ((Scalar)temp.getValue()).getHash();

         Iterator j = inside.getData().entrySet().iterator();
         while (j.hasNext())
         {
            temp = (Map.Entry)j.next();
            String feature = temp.getKey().toString();
            double weight  = ((Scalar)temp.getValue()).doubleValue();

            sum += ((Scalar)weights.getData().get(feature)).doubleValue() * weight;
         }

         puts(results, id, SleepUtils.getScalar(Math.tanh(sum)));
      }

      return results;
   }

   public Scalar feedForward(ScalarHash inputs, ScalarHash network0, ScalarHash network1)
   {
      Scalar ahidden = processLayer(network0, inputs);
      Scalar aoutput = processLayer(network1, ahidden.getHash());

      Scalar results = SleepUtils.getArrayScalar();
      results.getArray().push(aoutput);
      results.getArray().push(ahidden);
      results.getArray().push(SleepUtils.getHashScalar(inputs));

      return results;
   }

   public Scalar evaluate(String name, ScriptInstance script, Stack args)
   {
      if (name.equals("&soundex"))
      {
         return SleepUtils.getScalar(soundex(BridgeUtilities.getString(args, "")));
      }
      else if (name.equals("&edits"))
      {
         return SleepUtils.getArrayWrapper(edits(BridgeUtilities.getString(args, "")));
      }
      else if (name.equals("&edits2"))
      {
         return SleepUtils.getArrayWrapper(edits2(BridgeUtilities.getString(args, "")));
      }
      else if (name.equals("&editDistance"))
      {
         return SleepUtils.getScalar(editDistance(BridgeUtilities.getString(args, ""), BridgeUtilities.getString(args, "")));
      }
      else if (name.equals("&feedforward"))
      {
         try
         {
            ScalarHash inputs   = BridgeUtilities.getHash(args);
            ScalarHash network0 = BridgeUtilities.getHash(args);
            ScalarHash network1 = BridgeUtilities.getHash(args);

            return feedForward(inputs, network0, network1);
         }
         catch (Exception ex)
         {
            ex.printStackTrace();
         } 
      }
      else if (name.equals("&filterByDictionary"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         return SleepUtils.getArrayWrapper(filterByDictionary(model, BridgeUtilities.getString(args, ""), BridgeUtilities.getHash(args).getData()));
      }
      else if (name.equals("&editst"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         return SleepUtils.getArrayWrapper(  editst( model, BridgeUtilities.getHash(args).getData(), BridgeUtilities.getHash(args).getData(), BridgeUtilities.getString(args, "") ) );
      }
      else if (name.equals("&transition"))
      {
         Scalar results = transition(BridgeUtilities.getHash(args), BridgeUtilities.getArray(args), BridgeUtilities.getInt(args, 0));
         if (results != null)
           return results;
      }
      else if (name.equals("&Pword"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         double result = model.Pword(BridgeUtilities.getString(args, " "));

         if (Double.isNaN(result))
         {
            System.err.println("NaN &Pword");
         }

         return SleepUtils.getScalar(result);
      }
      else if (name.equals("&Pbigram1"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         double result = model.Pbigram1(BridgeUtilities.getString(args, " "), BridgeUtilities.getString(args, " "));
         return SleepUtils.getScalar(result);
      }
      else if (name.equals("&Pbigram2"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         String w1 = BridgeUtilities.getString(args, " ");
         String w2 = BridgeUtilities.getString(args, " ");

         double result = model.Pbigram2(w1, w2);
         return SleepUtils.getScalar(result);
      }
      else if (name.equals("&Ptrigram"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         double result = model.Ptrigram(BridgeUtilities.getString(args, " "), BridgeUtilities.getString(args, " "), BridgeUtilities.getString(args, " "));
         return SleepUtils.getScalar(result);
      }
      else if (name.equals("&Ptrigram2"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         double result = model.Ptrigram2(BridgeUtilities.getString(args, " "), BridgeUtilities.getString(args, " "), BridgeUtilities.getString(args, " "));
         return SleepUtils.getScalar(result);
      }
      else if (name.equals("&count"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         return SleepUtils.getScalar(model.count(BridgeUtilities.getString(args, "")));
      }
      else if (name.equals("&hasTrigram"))
      {
         LanguageModel model = (LanguageModel)(script.getScriptVariables().getScalar("$model").objectValue());
         return SleepUtils.getScalar(model.hasTrigram(BridgeUtilities.getString(args, ""), BridgeUtilities.getString(args, "")));
      }
      else if (name.equals("&scoreDistance"))
      {
         return SleepUtils.getScalar(scoreDifference(BridgeUtilities.getString(args, " ").charAt(0), BridgeUtilities.getString(args, " ").charAt(0)));
      }

      return SleepUtils.getEmptyScalar();
   }

   public void scriptLoaded(ScriptInstance script)
   {
      script.getScriptEnvironment().getEnvironment().put("&soundex", this);
      script.getScriptEnvironment().getEnvironment().put("&edits", this);
      script.getScriptEnvironment().getEnvironment().put("&edits2", this);
      script.getScriptEnvironment().getEnvironment().put("&editDistance", this);
      script.getScriptEnvironment().getEnvironment().put("&filterByDictionary", this);
      script.getScriptEnvironment().getEnvironment().put("&editst", this);
      script.getScriptEnvironment().getEnvironment().put("&feedforward", this);
      script.getScriptEnvironment().getEnvironment().put("&transition", this);
      script.getScriptEnvironment().getEnvironment().put("&Pword", this);
      script.getScriptEnvironment().getEnvironment().put("&Pbigram1", this);
      script.getScriptEnvironment().getEnvironment().put("&Pbigram2", this);
      script.getScriptEnvironment().getEnvironment().put("&Ptrigram", this);
      script.getScriptEnvironment().getEnvironment().put("&Ptrigram2", this);
      script.getScriptEnvironment().getEnvironment().put("&count", this);
      script.getScriptEnvironment().getEnvironment().put("&hasTrigram", this);
      script.getScriptEnvironment().getEnvironment().put("&scoreDistance", this);
   }

   public void scriptUnloaded(ScriptInstance script)
   {

   }
}
