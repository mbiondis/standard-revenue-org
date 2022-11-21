/**
 * @description ToggleBillingTriggers provides an interface that
 * enables a Flow to toggle the Salesforce Billing triggers,
 * usually for deleting Invoice records
 * 
 * @author      Martin Biondi
 */
public with sharing class ToggleCPQTriggers {

    public class CPQTriggers {
        @InvocableVariable public Boolean triggerState;
    }

    @InvocableMethod(label = 'ToggleCPQTriggers' description = 'Enable or disable the Salesforce CPQ triggers')
    public static void toggleEnabled(List<CPQTriggers> cpqParams) {

        if(cpqParams[0].triggerState)
            SBQQ.TriggerControl.enable();
        else {
            SBQQ.TriggerControl.disable();
        }
    }
}