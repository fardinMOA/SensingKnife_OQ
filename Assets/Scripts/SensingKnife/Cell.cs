using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Cell : MonoBehaviour
{
    public Collider Collider;


    void Start()
    {
        if (Collider == null)
        {
            Collider = GetComponent<Collider>();
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
