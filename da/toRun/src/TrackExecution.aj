import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.aspectj.lang.Signature;
import org.jhotdraw.samples.draw.Main;
 
public aspect TrackExecution{
 
	private static int callDepth = 0;
	//Map to store the number of calls
	private static Map<String,Integer> nrOfCalls = new HashMap<String, Integer>();
	//Map to store the frequency of calls made by parent to child
	private static Map<String,Integer> nrOfCallsByParent = new HashMap<String, Integer>();
	private static FileWriter fileWriter;
	//Declaration of output files
	private static String fileNameStackDepth = "stackDepth.csv";
	private static String fileNameNrOfCalls = "nrOfCalls.csv";
	private static String fileNameNrOfCallsByParent = "nrOfCallsByParent.csv";

	
	//The analysis should be called for the whole execution
    pointcut trackMethods() : (execution(* *(..)));
 
    /**
     *  Code executed before each method call. 
     */
    before(): trackMethods(){
    	callDepth++;
    	
    	Signature sig = thisJoinPointStaticPart.getSignature();
    	String name = sig.getName();
    	
    	
    	Integer count = nrOfCalls.get(name);
    	if(count == null){
    		nrOfCalls.put(name, 1);
    	} else {
    		nrOfCalls.put(name, ++count);
    	}
    	
		//Write method name and call depth to log
    	try {
    		fileWriter = new FileWriter(fileNameStackDepth, true);
			fileWriter.append(name + "," + callDepth + "\n");
			fileWriter.flush();
			fileWriter.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
    	
     	//Find the name of the caller method from the stack
		Thread current = Thread.currentThread();
		if(name != "main"){
	        StackTraceElement[] stack = current.getStackTrace();
	        String parent = stack[3].getMethodName();

	    	Integer countCall = nrOfCallsByParent.get(parent+"-"+name);
	    	if(countCall == null){
	    		nrOfCallsByParent.put(parent+"-"+name, 1);
	    	} else {
	    		nrOfCallsByParent.put(parent+"-"+name, ++countCall);
	    	}
		}
    }
    
    /**
     *  Code executed after each method call. 
     */
    after() throws IOException: trackMethods() {
    	callDepth--;
    	//Get the name of the method that was executed
    	Signature methodSignature = thisJoinPointStaticPart.getSignature();
    	String methodName = methodSignature.getName();
    	//Catch end of execution
    	if(methodName.equals("stop")) {
        	File fileNrOfCalls = new File(fileNameNrOfCalls);
        	File fileNrOfCallsByParent = new File(fileNameNrOfCallsByParent);

        	//Print number of calls for each method
        	Iterator nrOfCallsIterator = nrOfCalls.entrySet().iterator();
        	fileWriter = new FileWriter(fileNrOfCalls, false);

    	    while (nrOfCallsIterator.hasNext()) {
    	    	try {
    				Map.Entry pair = (Map.Entry)nrOfCallsIterator.next();
    				fileWriter.append((String)pair.getKey() + "," + pair.getValue().toString() + "\n");
    			} catch (Exception e) {
    			}
    	    }
    	
    		fileWriter.flush();
    		fileWriter.close();
    		nrOfCallsIterator.remove(); 
            
            //Print calling frequency in log
            Iterator nrOfCallsByParentIterator = nrOfCallsByParent.entrySet().iterator();
        	fileWriter = new FileWriter(fileNrOfCallsByParent, false);

    	    while (nrOfCallsByParentIterator.hasNext()) {
    	    	try {
    	    	Map.Entry pair = (Map.Entry)nrOfCallsByParentIterator.next();
    			fileWriter.append((String)pair.getKey() + "," + pair.getValue().toString() + "\n");
    	    	} catch (Exception e) {
    			}
    	    }
    		fileWriter.flush();
    		fileWriter.close();
    	}
    }
    
 
    public TrackExecution() {
    }
    
    /**
     * A main function for testing the trace aspect.
     * @throws IOException 
     */
    public static void main(String[] args) throws IOException{
    	clearLogs();
    	//Start the Main class that is tested
    	Main.main(args);
    	
		
    }
    
    private static void clearLogs() throws IOException{
    	//Clear the previous log files.
			File fileStackDepth = new File(fileNameStackDepth);
			fileStackDepth.delete();
			File fileNrOfCalls = new File(fileNameNrOfCalls);
			fileNrOfCalls.delete();
			File fileNrOfCallsByParent = new File(fileNameNrOfCallsByParent);
			fileNrOfCallsByParent.delete();
    }
}