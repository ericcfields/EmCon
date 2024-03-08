Guide for using arf script for artifact correction and rejection for EmCon data.

Author: Eric Fields  
Last Updated: 8 March 2024  

##### ICA correction #####

1. Visually inspect ICA components. You can see scalp maps of the components by going to Tools -> Inspect/label components by map. You can see the timecourse of each component's activity by going to Plot -> Component activations (scroll). Activity in components should be compared to the original data under Plot -> Channel data (scroll).
2. List all ICs to remove from data. For example: `ICrej = [1, 3];`
3. If one or more of the used ICs represent blinks, make sure `blink_corr = true;`

For more information on ICA correction see:  
https://eeglab.org/tutorials/06_RejectArtifacts/RunICA.html  
Ch. 6 Supplement in Luck (2014). An Introduction to the Event-Related
Potential Technique, 2nd ed. MIT Press.

##### Artifact detection & rejection #####

Each routine below has four parameters:
1. A voltage threshold in microvolts
2. The size of the moving window in milliseconds
3. The step bewteen consecutive moving window segments
4. The electrodes that the routine is applied to

After this script runs, visually inspect the data. If artifact rejection is not  satisfactory, respond no to save prompt, adjust threshold, and re-run the script. Usually you will adjust voltage thresholds and leave the time window parameters the same. Continue this procedure until you are satistifed, then save the artifact rejection.

For more on the detection routines and parameters, see:  
https://github.com/ucdavis/erplab/wiki/Tutorial-1-EEG-to-ERPset#artifact-detection  
https://github.com/ucdavis/erplab/wiki/Artifact-Detection-in-Epoched-Data  
Ch. 6 in Luck (2014). An Introduction to the Event-Related Potential Technique, 2nd ed. MIT Press.