using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class AudioManager : MonoBehaviour
{
    public LibPdInstance AudioEngine;
    public string FolderName = "20210810_cut/";
    public string FileName = "out_upsample.wav";
    public float Volume = 0.5f;

    public float InteractionValue = 0;


    void Start()
    {
        if (AudioEngine == null)
        {
            AudioEngine = GetComponent<LibPdInstance>();
        }

        AudioEngine.SendSymbol("_audioPath", Path.Combine(Application.streamingAssetsPath, "PdAssets/", FolderName, FileName));
    }

    
    void Update()
    {
        AudioEngine.SendFloat("_interaction", InteractionValue);
        AudioEngine.SendFloat("_volume", Volume);
    }
}
