//������
#define BACK		300
#define FORWARD		301
#define REFRESH		302
#define HOME		303
#define NEWTAB		304
#define GOTOURL		305
#define SEARCHWEB	306
#define ID1		178
#define ID2		177

#define WINDOWS	0
#define DOS		1
#define KOI		2
#define UTF		3
                      

dword get_URL_part(byte len) {
	char temp1[1000];
	copystr(#URL, #temp1);
	temp1[len] = 0x00;
	return #temp1;
}

inline byte chTag(dword text) {return strcmp(#tag,text);}


void GetURLfromPageLinks(int id) //������� �����, ������ ��� ������ ������� ������ ��������
{
	j = 0;
	for (i = 0; i <= id - 401; i++)
	{
		do j++;
		while (page_links[j] <>'|');
	}
	page_links[j] = 0x00;
	copystr(#page_links[find_symbol(#page_links, '|')], #URL);
}



//� ��� ��� ��������� ���⮢, ���⮬� ������ ������ ��
//����祪 ��� ��஦����� � ����⥫쭮� १����:
//������� ������� ��࠭� � �뢮��� �� ���⭮ ����᪠�� � ᬥ饭���,
//�� ���� ��४�� ���⨭��
//�� ����稨 䮭� � �.�. ����� ��� �����쭮��� �襭�� :)

//���� ������ 㦥 ����祭� � TBW - skin_width, Form.top, ������祭�� memory 
inline void Skew(dword x,y,w,h)
{
dword italic_buf;
int tile_height=2,//�㤥� �뢮���� ���寨�ᥫ�묨 ����᪠��
i, skin_width,
shift=-2;

  italic_buf = mem_Alloc(w*h*3);
  
  skin_width = GetSkinWidth();

  CopyScreen(italic_buf, x+Form.left+2, y+Form.top+skin_width, w, h);

  
  FOR (i=0;i*tile_height<h;i++){
    PutImage(w*3*tile_height*i+italic_buf,w,tile_height,x+shift-i+1,i*tile_height+y);
  }
  mem_Free(italic_buf);
}
