---
title: MFC程序添加背景图片的方法
category: 程序开发
date: 2011-04-25
comments: true
tags:
- MFC
- bmp
- jpg
- 双缓存
---

介绍两种为MFC程序的添加背景图片的方法：资源位图的方式和IPicture控件方式
## 1、资源位图的方式(背景图片只能是bmp格式，双缓存方式绘制防止闪烁)

需要先把以"bmp"为后缀的图片通过插入资源的方式添加到工程中，然后调用下面的函数即可
```
//////////////////////////////////////////////////////////////////////////
//功能：在pDC所在窗口上的DestRect区域内显示资源号bmpID指定的位图
//参数：
//   pDC:目的DC
//   bmpID:目的位图的资源号
//   DestRect:目的区域
//////////////////////////////////////////////////////////////////////////
bool DrawBK(CDC *pDC, UINT bmpID, CRect DestRect)
{
    CBitmap bitmap;
    bitmap.LoadBitmap(bmpID);

    BITMAP BitMap;
    bitmap.GetBitmap(&BitMap);

    CDC dcMem;
    dcMem.CreateCompatibleDC(pDC);
    dcMem.SelectObject(&bitmap);

    pDC->StretchBlt(DestRect.left,DestRect.top,DestRect.Width(),DestRect.Height(),&dcMem,0,0,BitMap.bmWidth,BitMap.bmHeight,SRCCOPY);

    return true;
}
```

## 2、借用控件IPicture加载图片的方式(背景图片可以是jpg格式)
```
//////////////////////////////////////////////////////////////////////////
//功能：在pDC所在窗口上的DestRect区域内显示path指定的图片
//参数：
//   pDC:目的DC
//   path:目的图片的路径
//   DestRect:目的区域
//////////////////////////////////////////////////////////////////////////
bool DrawBK(CDC* pDC,CString path,CRect DestRect)
{
    if(path.IsEmpty())
       return false;

    IStream *pStm;
    CFileStatus fstatus;
    CFile file;
    LONG cb;

    if(file.Open(path,CFile::modeRead)&&file.GetStatus(path,fstatus)&&((cb=fstatus.m_size)!=-1))
    {
       HGLOBAL hGlobal = GlobalAlloc(GMEM_MOVEABLE, cb);
       if(hGlobal != NULL)
       {
           LPVOID pvData = GlobalLock(hGlobal);
           if (pvData != NULL)
           {
               file.ReadHuge(pvData, cb);
               GlobalUnlock(hGlobal);
               CreateStreamOnHGlobal(hGlobal, TRUE, &pStm);
           }
       }
    }
    else
    {
       return false;
    }
	
    //显示图片
    IPicture *pPic;
    CoInitialize(NULL);

    if(SUCCEEDED(OleLoadPicture(pStm,fstatus.m_size,TRUE,IID_IPicture,(LPVOID*)&pPic)))
    {
       //得到源图像的大小
       OLE_XSIZE_HIMETRIC hmWidth;
       OLE_YSIZE_HIMETRIC hmHeight;
       pPic->get_Width(&hmWidth);
       pPic->get_Height(&hmHeight);

       //使用render函数显示图片
       if(FAILED(pPic->Render(*pDC,DestRect.left,DestRect.top,DestRect.Width(),DestRect.Height(),0,hmHeight,hmWidth,-hmHeight,NULL)))
       {
           pPic->Release();
           return false;
       }
       pPic->Release();
    }
    else
    {  
       return false;
    }
    CoUninitialize();
    return true;
}
```
有关问题欢迎发送邮件至lyingbo@aliyun.com一起讨论
