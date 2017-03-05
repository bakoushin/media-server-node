%module medooze
%{
	
#include <string>
#include "../media-server/include/config.h"	
#include "../media-server/include/dtls.h"	
#include "../media-server/include/media.h"
#include "../media-server/include/rtp.h"
#include "../media-server/include/DTLSICETransport.h"	
#include "../media-server/include/RTPBundleTransport.h"
#include "../media-server/include/mp4recorder.h"

class StringFacade : private std::string
{
public:
	StringFacade(const char* str) 
	{
		std::string::assign(str);
	}
	StringFacade(std::string &str) : std::string(str)
	{
		
	}
	const char* toString() 
	{
		return std::string::c_str();
	}
};

class PropertiesFacade : private Properties
{
public:
	void SetProperty(const char* key,int intval)
	{
		Properties::SetProperty(key,intval);
	}

	void SetProperty(const char* key,const char* val)
	{
		Properties::SetProperty(key,val);
	}
};

class MediaServer
{
public:
	static void Initialize()
	{
		//Start DTLS
		DTLSConnection::Initialize();
	}
	static StringFacade GetFingerprint()
	{
		return StringFacade(DTLSConnection::GetCertificateFingerPrint(DTLSConnection::Hash::SHA256).c_str());
	}
	
};

class StreamTransceiver : 
	public RTPIncomingSourceGroup::Listener,
	public RTPOutgoingSourceGroup::Listener
{
public:
	StreamTransceiver(RTPIncomingSourceGroup* incomingSource, DTLSICETransport* incomingTransport, RTPOutgoingSourceGroup* outgoingSource,DTLSICETransport* outgoingTransport)
	{
		//Store streams
		this->incomingSource = incomingSource;
		this->outgoingSource = outgoingSource;
		this->incomingTransport = incomingTransport;
		this->outgoingSource = outgoingSource;
		
		//Add us as listeners
		outgoingSource->AddListener(this);
		incomingSource->AddListener(this);
		
		//Request update on the incoming
		incomingTransport->SendPLI(incomingSource->media.ssrc);
	}

	virtual ~StreamTransceiver()
	{
		//Stop listeneing
		outgoingSource->RemoveListener(this);
		incomingSource->RemoveListener(this);	
	}

	virtual void onRTP(RTPIncomingSourceGroup* group,RTPPacket* packet)
	{
		//Change ssrc
		packet->SetSSRC(outgoingSource->media.ssrc);
		//Send it on transport
		outgoingTransport->Send(*packet);
	}
	
	virtual void onPLIRequest(RTPOutgoingSourceGroup* group,DWORD ssrc)
	{
		//Request update on the incoming
		incomingTransport->SendPLI(incomingSource->media.ssrc);
	}
private:
	RTPOutgoingSourceGroup *outgoingSource;
	RTPIncomingSourceGroup *incomingSource;
	DTLSICETransport* incomingTransport;
	DTLSICETransport* outgoingTransport;
};

%}
%include "stdint.i"
%include "../media-server/include/config.h"	

class StringFacade : private std::string
{
public:
	StringFacade(const char* str);
	StringFacade(std::string &str);
	const char* toString();
};

class PropertiesFacade : private Properties
{
public:
	void SetProperty(const char* key,int intval);
	void SetProperty(const char* key,const char* val);
};

class MediaServer
{
public:
	static void Initialize();
	static StringFacade GetFingerprint();
};


class StreamTransceiver : 
	public RTPIncomingSourceGroup::Listener,
	public RTPOutgoingSourceGroup::Listener
{
public:
	StreamTransceiver(RTPIncomingSourceGroup* incomingSource, DTLSICETransport* incomingTransport, RTPOutgoingSourceGroup* outgoingSource,DTLSICETransport* outgoingTransport);
	virtual ~StreamTransceiver();
	virtual void onRTP(RTPIncomingSourceGroup* group,RTPPacket* packet);
	virtual void onPLIRequest(RTPOutgoingSourceGroup* group,DWORD ssrc);
private:
	RTPOutgoingSourceGroup *outgoing;
	RTPIncomingSourceGroup *incoming;
};


%include "../media-server/include/media.h"
%include "../media-server/include/rtp.h"
%include "../media-server/include/DTLSICETransport.h"
%include "../media-server/include/RTPBundleTransport.h"
%include "../media-server/include/mp4recorder.h"
