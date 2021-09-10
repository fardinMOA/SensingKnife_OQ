using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class ExtensionMethods
{

    public static float Remap(this float value, float from1, float to1, float from2 = 0, float to2 = 1, bool clamped = true)
    {
        if (clamped)
        {
            return Mathf.Clamp((value - from1) / (to1 - from1) * (to2 - from2) + from2, to1, to2);
        }
        return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
    }

}
