import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.aspectj.lang.Signature;
import org.jhotdraw.samples.draw.Main;
 
public aspect Trace{
 
	private static int callStack = -1;
	//The files that store the results
	private static String fileName = "trace.csv";
	private static String fileNameFrequency = "frequency.csv";
	private static String fileNameCalls = "calls.csv";
	//Map to store the frequency of call
	private static Map<String,Integer> counts = new HashMap<String, Integer>();
	//Map to store the frequency of calls made by each method to a certain other method
	private static Map<String,Integer> countCalls = new HashMap<String, Integer>();
	private static FileWriter writer;
	
	//The analysis should be called for the whole execution
    pointcut traceMethods() : (execution(* *(..)));
 
    /**
     * This is called before each method call.
     */
    before(): traceMethods(){
    	callStack++;
    	
    	Signature sig = thisJoinPointStaticPart.getSignature();
    	String name = sig.getName();
    	Integer count = counts.get(name);
    	if(count == null){
    		counts.put(name, 1);
    	} else {
    		counts.put(name, ++count);
    	}

     	//Get name of method calling current method
		Thread current = Thread.currentThread();
		if(name!="main"){
	        StackTraceElement[] stack = current.getStackTrace();
	        String parent = stack[3].getMethodName();

	    	Integer countCall = countCalls.get(parent+"-"+name);
	    	if(countCall == null){
	    		countCalls.put(parent+"-"+name, 1);
	    	} else {
	    		countCalls.put(parent+"-"+name, ++countCall);
	    	}
		}
		
		//Write method name and call depth to log
    	try {
    		writer = new FileWriter(fileName, true);
			writer.append(name);
			writer.append(",");
			writer.append(callStack+"");
			writer.append("\n");
			writer.flush();
			writer.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
    }
    
    /**
     * This is called after each method call.
     */
    after() throws IOException: traceMethods() {
    	callStack--;
    	//Get name of method
    	Signature sig = thisJoinPointStaticPart.getSignature();
    	String name = sig.getName();
    	if(name.equals("stop")) {
        	File fileFrequency = new File(fileNameFrequency);
        	File fileCalls = new File(fileNameCalls);

        	//Print frequency in log
        	Iterator it = counts.entrySet().iterator();
        	writer = new FileWriter(fileFrequency, true);

    	    while (it.hasNext()) {
    	    	try {
    				Map.Entry pair = (Map.Entry)it.next();
    				writer.append((String)pair.getKey());
    				writer.append(",");
    				writer.append(pair.getValue().toString());
    				writer.append("\n");
    			} catch (Exception e) {
    			}
    	    }
    	
    		writer.flush();
    		writer.close();
            it.remove(); 
            
            //Print calling frequency in log
            Iterator it2 = countCalls.entrySet().iterator();
        	writer = new FileWriter(fileCalls, true);

    	    while (it2.hasNext()) {
    	    	try {
    	    	Map.Entry pair = (Map.Entry)it2.next();
    			writer.append((String)pair.getKey());
    			writer.append(",");
    			writer.append(pair.getValue().toString());
    			writer.append("\n");
    	    	} catch (Exception e) {
    			}
    	    }
    		writer.flush();
    		writer.close();
    	}
    }
    
 
    public Trace() {
    }
    
    /**
     * A main function for testing the trace aspect.
     * @throws IOException 
     */
    public static void main(String[] args) throws IOException {
    	//Clear previous instances of the logs.
    	File file = new File(fileName);
		file.delete();
    	File fileFrequency = new File(fileNameFrequency);
    	fileFrequency.delete();
    	File fileCalls = new File(fileNameCalls);
    	fileFrequency.delete();
 
    	//Start the Main class that is tested
    	Main.main(args);
    	
		
    }
}