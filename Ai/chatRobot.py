#!/usr/bin/python

# -*- python -*-
#
# $Id: chatRobot.py  2019-06-27 22:18:47 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-27 22:18:47
#    Description : 
#************************************************************************

'''
#https://blog.csdn.net/qq_39046854/article/details/83834628
import sys; print(sys.stdout.encoding)

import wave
from pyaudio import PyAudio,paInt16

def save_wave_file(filename,data): 
    wf=wave.open(filename,'wb')
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(8000)
    wf.writeframes(b"".join(data))
    wf.close()

def my_record(): 
    pa=PyAudio()
    stream=pa.open(format = paInt16,channels=1,
                   rate=8000,input=True,
                   frames_per_buffer=2000)
    my_buf=[]
    count=0
    print("正在录音")
    while count<2*15: 
        audio= stream.read(2000)
        my_buf.append(audio)
        count+=1
        # print('.')
    save_wave_file('01.wav',my_buf) 
    stream.close()
    print("录音完成！")

#pip install baidu_aip
from aip import AipSpeech
def audio_word():
    APP_ID = ''
    API_KEY = ''
    SECRET_KEY = ''
    client = AipSpeech(APP_ID, API_KEY, SECRET_KEY)
    def get_file_content(filePath):
        with open(filePath, 'rb') as fp:
            return fp.read()
    ret = client.asr(get_file_content('01.wav'), 'wav', 16000, {'dev_pid': 1537, })
    print(ret) 
'''

import requests
import json
def reqChat(text): 
    url = "http://www.tuling123.com/openapi/api"
    query = {'key': 'e43860d1de0546b7b0ee5143f28a18ae', 'info': text.encode('utf-8'), 'userid': '12345678'}
    headers = {'Content-type': 'text/html', 'charset': 'utf-8'}
    res = requests.post(url, params=query, headers=headers)
    jRes = json.loads(res.text)
    return (jRes.get('text'))

import pyttsx3         
engine = pyttsx3.init()
#engine.setProperty('voice', 'zh')
while True: 
    line = input("me:")
    res = reqChat(line)
    print('NoName:'+res)
    engine.say(res)
    if line == 'bye': 
        break

    engine.runAndWait()
    