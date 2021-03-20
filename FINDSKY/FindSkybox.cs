using UnityEngine;

public class FindSkybox : MonoBehaviour
{
    private void Start()
    {
        ServiceProvider.Instance.DevConsole.RegisterCommand("FindSkyDome", FindSkyDome);
    }

    private void FindSkyDome()
    {
        GameObject sky = GameObject.Find("SkyDome_Low(Clone)");

        if (sky == null)
        {
            Debug.LogError("SkyDome not found");
        }
        else
        {
            Component[] components = sky.GetComponents<Component>();
            
            for (int i = 0; i < components.Length; i++)
            {
                Debug.Log("SkyDome component found: " + components[i].GetType());
            }
        }
    }
}

/*
 * SkyDome component found: UnityEngine.Transform 
 * SkyDome component found: TOD_Sky 
 * SkyDome component found: TOD_Animation 
 * SkyDome component found: TOD_Time 
 * SkyDome component found: TOD_Components 
 * SkyDome component found: TOD_Resources
 */
