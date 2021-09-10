using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Knife : MonoBehaviour
{
    public List<Cell> Cells;
    public Transform KnifeBlade;
    public MeshRenderer KnifeRenderer;

    public float interactionValue = 0;

    float vel;


    void Start()
    {
        
    }



    void Update()
    {
        if (Cells.Count != 0)
        {
            float newVal = GetDistanceToClosesCollider().Remap(0.25f, 0);
            interactionValue = Mathf.SmoothDamp(interactionValue, newVal, ref vel, 0.1f);
        }

        KnifeRenderer.sharedMaterial.SetFloat("Interaction", interactionValue);
        
    }

    float GetDistanceToClosesCollider()
    {
        Collider closest = Cells[0].Collider;
        float dist = GetDistance(closest, KnifeBlade);
        foreach (var cell in Cells)
        {
            float currDist = GetDistance(cell.Collider, KnifeBlade);
            if (currDist < dist)
            {
                //TODO: some weighting would be amazing here, instead of jumping form one to the next
                dist = currDist;
            }
        }

        return dist;
    }



    float GetDistance(Collider col, Transform point)
    {
        return Mathf.Abs(Vector3.Distance(col.ClosestPoint(point.position), point.position));
    }
}
