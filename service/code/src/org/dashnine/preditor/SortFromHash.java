package org.dashnine.preditor;

import sleep.runtime.*;
import sleep.bridges.*;
import sleep.interfaces.*;

import java.util.*;

/* Code to implement a sort function that sorts values by their corresponding Double values in a hashtable. This class exists to replace
   <code>sort(lambda({ return %hash[$1] <=> %hash[$2]; }, \%hash)</code>.  This snippet was identified by the profiler as consuming more time
   than any other function */
public class SortFromHash implements Loadable
{
    private static class CompareHashItems implements Comparator
    {
        protected ScalarHash     hash;

        public CompareHashItems(ScalarHash _hash)
        {
           hash = _hash;
        }

        public int compare(Object a, Object b)
        {
           double aa, bb;
           aa = hash.getAt((Scalar)a).doubleValue();
           bb = hash.getAt((Scalar)b).doubleValue();           

           if (aa > bb)
           {
              return -1;
           }
           else if (aa < bb)
           {
              return 1;
           }
           else
           {
              return 0;
           }
        }
    }

    private static class func_sortFromHash implements Function
    {
        public Scalar evaluate(String n, ScriptInstance i, Stack l)
        {
           ScalarArray  array     = BridgeUtilities.getWorkableArray(l);
           ScalarHash   hash      = BridgeUtilities.getHash(l);

           array.sort(new CompareHashItems(hash));

           return SleepUtils.getArrayScalar(array);
        }
    }

   public void scriptLoaded(ScriptInstance script)
   {
      script.getScriptEnvironment().getEnvironment().put("&sortHash", new func_sortFromHash());
   }

   public void scriptUnloaded(ScriptInstance script)
   {
   }
}
