using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class KnifeManager : MonoBehaviour
{
    public List<Knife> Knifes;
    public List<Cell> Cells;
    public AudioManager Audio;


    void Start()
    {
        foreach (var k in Knifes)
        {
            k.Cells = Cells;
        }
    }

    void Update()
    {
        float val = 0;
        foreach (var k in Knifes)
        {
            val += k.interactionValue;
        }
        val /= Knifes.Count;
        Audio.InteractionValue = val;
    }
}
