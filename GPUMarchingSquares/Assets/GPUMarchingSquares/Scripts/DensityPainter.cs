using UnityEngine;
using System.Collections;

public class DensityPainter : MonoBehaviour
{

    [SerializeField]
    GPUMarchingSquares _gpuMarchingSquaresScript;

    [SerializeField]
    Shader _densityPaintShader;

    [SerializeField, Range(1, 1024)]
    int _texWidth = 512;
    [SerializeField, Range(1, 1024)]
    int _texHeight = 512;

    RenderTexture[] _buffers;
    
    public float Thickness = 0.05f;
    public float Alpha = 0.5f;

    [SerializeField]
    bool _isMouseLeftButtonDown = false;
    [SerializeField]
    bool _isMouseRightButtonDown = false;

    Material _densityPaintMat;

    [SerializeField]
    bool _enableShowDebugTex = false;

    void Start()
    {
        _buffers = new RenderTexture[2];
        _buffers[0] = new RenderTexture(_texWidth, _texHeight, 0, RenderTextureFormat.ARGB32);
        _buffers[0].hideFlags = HideFlags.DontSave;
        _buffers[0].filterMode = FilterMode.Bilinear;
        _buffers[1] = new RenderTexture(_texWidth, _texHeight, 0, RenderTextureFormat.ARGB32);
        _buffers[1].hideFlags = HideFlags.DontSave;
        _buffers[1].filterMode = FilterMode.Bilinear;

        Graphics.SetRenderTarget(_buffers[0]);
        GL.Clear(false, true, new Color(0, 0, 0, 1));
        Graphics.SetRenderTarget(null);
        Graphics.SetRenderTarget(_buffers[1]);
        GL.Clear(false, true, new Color(0, 0, 0, 1));
        Graphics.SetRenderTarget(null);
        
        if (_densityPaintMat == null)
        {
            _densityPaintMat = new Material(_densityPaintShader);
            _densityPaintMat.hideFlags = HideFlags.HideAndDontSave;
        }

        _gpuMarchingSquaresScript.DensityTex = _buffers[0];
    }

    void Update()
    {
        var mp = Input.mousePosition;
        mp.z = 10.0f;

        if (Input.GetMouseButtonDown(0))
        {
            _isMouseLeftButtonDown = true;
        }

        if (Input.GetMouseButtonDown(1))
        {
            _isMouseRightButtonDown = true;
        }

        if (Input.GetMouseButtonUp(0))
        {
            _isMouseLeftButtonDown = false;
        }

        if (Input.GetMouseButtonUp(1))
        {
            _isMouseRightButtonDown = false;
        }

        if (Input.GetKeyUp("r"))
        {
            Graphics.SetRenderTarget(_buffers[0]);
            GL.Clear(false, true, new Color(0, 0, 0, 1));
            Graphics.SetRenderTarget(null);

            Graphics.SetRenderTarget(_buffers[1]);
            GL.Clear(false, true, new Color(0, 0, 0, 1));
            Graphics.SetRenderTarget(null);
        }

        float asp = (float)Screen.width / Screen.height;
        var mouseParams = new Vector4(
        mp.x / (1.0f * Screen.width) * asp - (asp - 1.0f) * 0.5f,
        mp.y / (1.0f * Screen.height),
        (_isMouseLeftButtonDown || _isMouseRightButtonDown) ? Thickness : 0.0f,
         _isMouseRightButtonDown ? 0.0f : (_isMouseLeftButtonDown ? 1.0f : 0.0f)
        );

        _densityPaintMat.SetVector("_Mouse", mouseParams);
        _densityPaintMat.SetFloat("_Thickness", Thickness);
        _densityPaintMat.SetFloat("_Alpha", Alpha);
        Graphics.Blit(_buffers[0], _buffers[1], _densityPaintMat, 0);
        
        SwapBuffer(ref _buffers[0], ref _buffers[1]);
    }

    void OnDestroy()
    {
        if(_buffers != null && _buffers.Length > 0)
        {
            for(var i = 0; i < _buffers.Length; i++)
            {
                DestroyImmediate(_buffers[0]);
            }
            _buffers = null;
        }
    }

    void OnGUI()
    {
        if (_enableShowDebugTex)
        {
            if (_buffers != null && _buffers.Length > 0)
            {
                float asp = (float)Screen.width / Screen.height;
                Rect rect = new Rect((Screen.width - Screen.height) * 0.5f, 0, Screen.width * (1.0f/asp), Screen.height);
                GUI.DrawTexture(rect, _buffers[0]);
            }
        }
    }

    void SwapBuffer(ref RenderTexture ping, ref RenderTexture pong)
    {
        RenderTexture temp = ping;
        ping = pong;
        pong = temp;
    }
}

