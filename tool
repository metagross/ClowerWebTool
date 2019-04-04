import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.*;

import javax.swing.plaf.synth.SynthSeparatorUI;

public class tool{
	public tool() {
		
	}
	
	public void nslookup(String addr) {
        InetAddress inetaddr[] = null; 
        
        try { 
            inetaddr = InetAddress.getAllByName( addr ); 
        } catch( UnknownHostException e ) { 
            e.printStackTrace(); 
        } 
        
        for( int i = 0; i < inetaddr.length; i++ ) { 
        	StringBuilder sb = new StringBuilder(inetaddr[i].getHostName()).append("\n")
        			.append(inetaddr[i].getHostAddress()).append("\n")
        		.append(inetaddr[i].toString() ).append("\n")
        		.append("----------------------------------\n");
        }
	}
	
	public webToon naverWebToonInfo(int titleID) {
		String myhtml, toonName = null, autorName = null;
		webToon toon = null;
		int pageCount=-1, indTemp;
		try{
	            myhtml = loadHTML_toString("https://comic.naver.com/webtoon/list.nhn?titleId="+titleID, "utf-8");
	            
	            //============================================================================
	            //pageNumber찾기
	            //============================================================================
	            indTemp = myhtml.indexOf("no=",
	    	            myhtml.indexOf("<a href=\"webtoon/detail.nhn?titleId=", 
	    	    	            myhtml.indexOf("tbody",
	    	    	            		myhtml.indexOf("table cellpadding=\"0\" cellspacing=\"0\" class=\"viewList\""))))+"no=".length();
	            
	            StringBuilder sb = new StringBuilder();
	            while(myhtml.charAt(indTemp) != '&') {
	            	sb.append(myhtml.charAt(indTemp));
	            	indTemp++;
	            }
	            pageCount = Integer.parseInt(new String(sb));
	            

	            //============================================================================
	            //Title찾기
	            //============================================================================
	            indTemp = myhtml.indexOf("<h2>",
	            		myhtml.indexOf("<div class=\"detail\">", 
	            				myhtml.indexOf("<div class=\"comicinfo\"",
	            						myhtml.indexOf("<div id=\"content\" class=\"webtoon\">"))))+"<h2>".length();
	            
	            sb = new StringBuilder();
	            while(myhtml.charAt(indTemp) == ' ' || myhtml.charAt(indTemp) == '\t' || myhtml.charAt(indTemp) == '\n'
	            		|| myhtml.charAt(indTemp) == 13){
	            	indTemp++;
            	}
	            
	            while(myhtml.charAt(indTemp) != '<') {
	            	sb.append(myhtml.charAt(indTemp));
	            	indTemp++;
	            }
	            toonName = new String(sb);
	            
	            

	            //============================================================================
	            //autor 찾기 (Title찾기에서 바로 이어서)
	            //============================================================================
	            
	            sb = new StringBuilder();
	            indTemp+="span class=\"wrt_nm\">".length();
	            
	            // '>' 넘기기
	            indTemp++;
	            
	            while(myhtml.charAt(indTemp) == ' ' || myhtml.charAt(indTemp) == '\t' || myhtml.charAt(indTemp) == '\n'
	            		|| myhtml.charAt(indTemp) == 13){
	            	indTemp++;
            	}
	            
	            while(myhtml.charAt(indTemp) != '<') {
	            	sb.append(myhtml.charAt(indTemp));
	            	indTemp++;
	            }
 	            autorName = new String(sb); 
 	            
	        }catch(Exception e){
	            e.printStackTrace();
	        }
		toon = new webToon(toonName, pageCount, autorName);
		return toon;
	}
	
	public void clowingWebToon(int TitleID) {
		webToon wt = naverWebToonInfo(TitleID);
		File f = new File("./webToon/"+wt.getName());
		File info;
		String existing_name = null;
		int existing_pageCount = -1;
		PrintWriter saveInfo;
		
		
		if(!f.exists()) {
			f.mkdirs();
			info = null;
		}
		
		info = new File(f.getAbsolutePath()+"/info.txt");
		if(info.exists()){
			try {
				BufferedReader br = new BufferedReader(new FileReader(info));
				existing_name = br.readLine();
				existing_pageCount = Integer.parseInt(br.readLine());
				br.close();
				
				if(!existing_name.equals(wt.getName())) {
					System.out.println("데이터 무결성 침해.  작업 종료");
					return;
				}
				
				if(wt.getPageCount() <= existing_pageCount) {
					return;
				}
				
				do{
					//webToon저장
					existing_pageCount++;
					saveWebToon(f.getAbsolutePath(), TitleID, existing_pageCount);
				}while(existing_pageCount < wt.getPageCount());
				
			} catch (FileNotFoundException e) {
				e.printStackTrace();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}else {
			existing_pageCount = 0;
			do{
				//webToon저장
				existing_pageCount++;
				saveWebToon(f.getAbsolutePath(), TitleID, existing_pageCount);
			}while(existing_pageCount < wt.getPageCount());
		}
		
		
		//info.txt 저장하기
		try {
			saveInfo = new PrintWriter(new FileWriter(f.getAbsolutePath()+"/info.txt"));
			saveInfo.println(wt.getName());
			saveInfo.println(wt.getPageCount());
			saveInfo.println(wt.getAutor());
			saveInfo.close();
		}
		catch(IOException e) {
			
		}
	}
	
	public String loadHTML_toString(String urlPath, String charset) {
		try {
	        URL url = new URL(urlPath);
	        URLConnection con = (URLConnection)url.openConnection();
	        InputStreamReader reader = new InputStreamReader (con.getInputStream(), charset);
	        String pageContents = null;
			StringBuilder contents = new StringBuilder();

	        BufferedReader buff = new BufferedReader(reader);

	        while((pageContents = buff.readLine())!=null){
	            //System.out.println(pageContents);             
	            contents.append(pageContents);
	            contents.append("\r\n");
	        }
	        buff.close();
	        return contents.toString();
	        
		}catch(IOException e) {
			
		}
		return null;
	}
	
	public int saveWebToon(String savePath, int TitleID, int existing_pageCount) {
		File webtoonFolder;
		String webHTML, temp[];
		int strpoint;
		
		String ext;
		
		
		webtoonFolder = new File(savePath+"/"+existing_pageCount+"/");
		webtoonFolder.mkdirs();
		
		webHTML = loadHTML_toString("https://comic.naver.com/webtoon/detail.nhn?titleId="
				+TitleID+"&no="+existing_pageCount+"&weekday=wed", "utf-8");
		
		strpoint = webHTML.indexOf("<div class=\"wt_viewer\"", 
				webHTML.indexOf("<div class=\"view_area\" id=\"comic_view_area\">"))+"<div class=\"wt_viewer\"".length();
		while(webHTML.charAt(strpoint) != '>') {
			strpoint++;
		}
		strpoint++;
		
		//========================================
		//문자열 정리 작업
		//========================================
		webHTML = webHTML.substring(strpoint);
		webHTML = webHTML.substring(0, webHTML.indexOf("</div>"));
		webHTML = deleteAllEmptySpace(webHTML);
		
		temp = webHTML.split("<imgsrc=\"");
		for(int i=1;i<temp.length;i++) {
			temp[i] = temp[i].substring(0,temp[i].indexOf("\""));
			ext = temp[i].substring(temp[i].lastIndexOf('.'), temp[i].length());
			try {
				byte b[] = new byte[1024];
				int length;
				FileOutputStream fos;
				BufferedInputStream is;
				is = getImageInputStreamToUrl(temp[i]);
				fos = new FileOutputStream(webtoonFolder.getAbsoluteFile()+"/"+i+ext);
				while ((length = is.read(b)) != -1) {
					fos.write(b, 0, length);
				}
				fos.close();
			} catch (MalformedURLException e) {
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		return 0;
	}
	
	private BufferedInputStream getImageInputStreamToUrl(String urlString) {
		try {
			URLConnection uc;
			uc = new URL(urlString).openConnection();
			uc.addRequestProperty("User-Agent", 
			  "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)");
			uc.connect();
			uc.getInputStream();
			
			return new BufferedInputStream(uc.getInputStream());
		}catch(Exception e) {
    		e.printStackTrace();
    	}
		return null;
	}
	
	private String deleteAllEmptySpace(String mstr) {
		mstr = mstr.replaceAll(" ", "");
		mstr = mstr.replaceAll(Character.toString ((char) 13), "");
		mstr = mstr.replaceAll("\n", "");
		mstr = mstr.replaceAll("\t", "");
		return mstr;
		
	}
	
	boolean autoClowerLogic;
	
	public void start() {
		while(autoClowerLogic) {
			
		}
	}
	
	class webToon{
		private int pageCount;
		private final String name;
		private final String autor;
		
		public webToon(String name, int pageCount, String autor) {
			this.name = name;
			this.pageCount = pageCount;
			this.autor = autor;
		}
		
		public String getName() {
			return name;
		}

		public String getAutor() {
			return autor;
		}
		
		public int getPageCount() {
			return pageCount;
		}
	}
	
	
	class webToonSchima extends webToon{
		private final int webCode;
		private int seris_state;	//0 end, 1 be publising
		public int serisSleepCount;
		
		public webToonSchima(String name, int pageCount, String autor, int webCode, int seris_state) {
			super(name, pageCount, autor);
			this.webCode = webCode;
			this.seris_state = seris_state;
		}
		
		public int getSeris_state() {
			return seris_state;
		}
		
		public int getWebCode() {
			return webCode;
		}
	}
}
