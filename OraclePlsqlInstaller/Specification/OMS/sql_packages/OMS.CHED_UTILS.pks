
  CREATE OR REPLACE PACKAGE "OMS"."CHED_UTILS" IS

/*

         $Id: OMS.CHED_UTILS.pks 2916 2011-11-10 04:22:40Z RHolliday $
    $HeadURL: https://corpvmcoderep01.corp.chedha.net/svn/gisoms/Projects/src/OMS/src/OMS/sql_packages/OMS.CHED_UTILS.pks $
       $Date: 2011-11-10 15:22:40 +1100 (Thu, 10 Nov 2011) $

Copyright (c) Ched Services 2010

 *
 * Purpose
 *   Aggregates functions/procedure/type related with incidents.
 *
 */


TYPE oms_cursor IS REF CURSOR;
TYPE tbl_str    IS TABLE OF VARCHAR2(256) ;


/*
 * Function outage_head_location
 *   Given an incident returns the location of the latest outage head. Current and non-current
 *   outage heads are considered (useful to get the location for restored orders).
 *
 *   For outage with multi outage heads the latest is picked up (or randomly one if their
 *   timestamp is the same).
 */
FUNCTION outage_head_location(p_incident_id  IN NUMBER,
                              p_current_only IN NUMBER := 0) RETURN VARCHAR2 ;


/*
 * Procedure zones_for_type
 *   Parameter out p_ref_cursor is a cursor with the zones existing for the type given.
 *   Parameter p_business_code allows to filter the zones list by company. If NULL all
 *   zones will be shown. Valid values are '8000' for PAL and '9000' for CP.
 *   Proxy zones or zones with no normal span will not appear on the list.
 */
PROCEDURE zones_for_type(p_type          IN po_elec_zone.TYPE%TYPE,
                         p_business_code IN CHED_ORDER_EXT.business_code%TYPE,
                         p_ref_cursor    OUT oms_cursor) ;


/*
 * Procedure substations_for_type
 *   Parameter out p_ref_cursor is a cursor with the substations names existing for the
 *   type given. Note that the substations names are the zone names with the last
 *   characters truncated.
 *   Parameter p_business_code allows to filter the zones list by company. If NULL all
 *   zones will be shown. Valid values are '8000' for PAL and '9000' for CP.
 *   Proxy zones or zones with no normal span will not appear on the list.
 */
PROCEDURE substations_for_type(p_type          IN po_elec_zone.TYPE%TYPE,
                               p_business_code IN CHED_ORDER_EXT.business_code%TYPE,
                               p_ref_cursor    OUT oms_cursor) ;


/*
 * Procedure feeders_for_zone
 *   Parameter out p_ref_cursor is a cursor with the zones existing for the zone id given
 *   (p_zone_id).
 */
PROCEDURE feeders_for_zone(p_zone_id    IN po_elec_zone.ID%TYPE,
                           p_ref_cursor OUT oms_cursor) ;


/*
 * Function feeders_for_zone_ids
 *   Returns a comma separated string with the break ids for the feeders of the zone id given.
 */
FUNCTION feeders_for_zone_ids(p_zone_id IN po_elec_zone.ID%TYPE) RETURN VARCHAR2 ;


/*
 * Function stn_switches_cb_for_zone_ids
 *   Returns a comma separated string with the break ids for the Stn switches CB for the zone id given.
 */
FUNCTION stn_switches_cb_for_zone_ids(p_zone_id IN po_elec_zone.ID%TYPE) RETURN VARCHAR2 ;


/*
 * FUNCTION zone_for_break
 *   Returns the zone name for the given break (normal state). Returns NULL if the break
 *   doesn't exists. If the break is a tie break (ie, normally open and connected to two zones,
 *   one on each side) returns randomly one of the zones.
 */
FUNCTION zone_for_break(p_break_id IN po_int_elec_break.ID%TYPE) RETURN VARCHAR2 ;


/*
 * PROCEDURE zone_info_for_break
 *   Returns the zone name, id, normal span id, zone type and substation name for the zone associated
 *   with the break (normal state).
 *   Returns NULL if the break doesn't exists. If the break is a tie break (ie, normally open and
 *   connected to two zones, one on each side) returns randomly the information for one of the zones.
 */
PROCEDURE zone_info_for_break(p_break_id       IN  po_int_elec_break.ID%TYPE
                             ,p_zone_name      OUT po_elec_zone.NAME%TYPE
							 ,p_zone_id        OUT po_elec_zone.ID%TYPE
							 ,p_normal_span_id OUT po_elec_zone.ID%TYPE
							 ,p_zone_type      OUT po_elec_zone.TYPE%TYPE
							 ,p_subst_name     OUT po_elec_zone.SUBSTATION_NAME%TYPE) ;


/*
 * FUNCTION order_for_break
 *   Returns the reference label for the order associated with the break.
 *   Returns NULL if no order exists associated with the break.
 *   Note that a open break can have two outages (orders) associated (one on
 *   each side
 */
FUNCTION order_for_break(p_break_id IN po_int_elec_break.ID%TYPE) RETURN VARCHAR2 ;


/*
 * FUNCTION cod_dev_type
 *   Returns the device type according to device's rwo code.
 */
FUNCTION cod_dev_type(p_rwo_code IN NUMBER) RETURN NUMBER ;


/*
 * PROCEDURE downstream_breaks_cod
 *   Wrapper procedure to call downstream_breaks_c from package ched_network_explorer.
 *   Needed because VB has limitations on how to handle PL/SQL collections.
 */
PROCEDURE downstream_breaks_cod(p_break_id     	 		IN  po_int_elec_break.ID%TYPE,
						        p_no_customers 			IN  NUMBER := 0,
								p_limit_to_break_zone 	IN NUMBER := 1,
                                p_cursor       			OUT ched_utils.oms_cursor) ;


/*
 * PROCEDURE downstream_stn_switch_cb
 *   Wrapper procedure to call downstream_breaks_c from package ched_network_explorer.
 *   The set returned will only include HV Station switches with function CB (ie, the feeders).
 *   Needed because VB has limitations on how to handle PL/SQL collections.
 */
PROCEDURE downstream_stn_switch_cb(p_break_id IN  po_int_elec_break.ID%TYPE,
								   p_cursor   OUT ched_utils.oms_cursor) ;


/*
 * FUNCTION downstream_stn_switch_cb_ids
 *   Returns a comma separated string with the break ids for the Stn Switches CB that
 *   are downstream the given break.
 */
FUNCTION downstream_stn_switch_cb_ids(p_break_id IN po_int_elec_break.ID%TYPE) RETURN VARCHAR2 ;


/*
 * PROCEDURE upstream_breaks
 *   Helper proc defined to be called in Magik. Calls the procedure with the same name
 *   defined in ched_network_explorer.

 */
PROCEDURE upstream_breaks(p_break_id            IN  po_int_elec_break.ID%TYPE,
						  p_limit_to_break_zone IN  NUMBER := 0               ) ;


/*
 * PROCEDURE customers_info
 *   Get customers information
 *   Needed to Customers on Device.
 */
PROCEDURE customers_info(p_break_id   IN  po_int_elec_break.ID%TYPE,
						 p_ref_cursor OUT oms_cursor) ;


/*
 * Procedure device_and_customers_info
 *   Parameter out p_ref_cursor is a cursor with the devices/customer information.
 */
PROCEDURE device_and_customers_info(p_break_id   IN po_int_elec_break.ID%TYPE,
                                    p_ref_cursor OUT oms_cursor) ;


/*
 * Procedure device_and_cust_info_sorted
 *   Parameter out p_ref_cursor is a cursor with the devices/customer information sorted by
 *   tree level, parent, address (obtained only for supply points and customers) and sequence
 *   in the tree level.
 */
PROCEDURE device_and_cust_info_sorted(p_break_id   IN po_int_elec_break.ID%TYPE,
                                      p_ref_cursor OUT oms_cursor) ;



 /*
 * Procedure device_and_wide_cust_info
 *   Parameter out p_ref_cursor is a cursor with the devices/customer information sorted by
 *   tree level, parent, address (obtained only for supply points and customers) and sequence
 *   in the tree level. This also includes all customers with a valid supply point and provisioning that
 *   are not in the CHED_CUSTOMER table.
2016-08-26 Simon Bond
 */
PROCEDURE device_and_wide_cust_info(p_break_id   IN po_int_elec_break.ID%TYPE,
                                      p_ref_cursor OUT oms_cursor) ;




/*
 * hv_zone_for
 *   Given a GIS id, assigns to p_hv_zone_name the name of HV zone and to p_break_id the
 *   corresponding break id (NULL if no associated break exists).
 *
 *   That HV zone name is:
 *     o The HV parent zone name if the device is LV.
 *     o The device zone name if the device is HV.
 *
 *   p_hv_zone_name will be NULL if the conditions indicated above don't apply. In that
 *   case, argument p_err_code will indicate the reason.
 *
 *   The possible values and meanings for p_err_code are:
 *     o 0
 *       p_hv_zone_name found (ie, no error).
 *     o -1
 *       The device doesn't has a break associated (ie, it's unknown to PowerOn).
 *     o -2
 *       The device is a LV device but the associated LV zone doesn't has a upstream
 *       HV zone.
 *     o -3
 *       The device is a ST device.
 */
PROCEDURE hv_zone_for(p_gis_id       IN  NUMBER,
                      p_hv_zone_name OUT VARCHAR2,
					  p_break_id     OUT NUMBER,
					  p_err_code     OUT NUMBER) ;


/*
 * hv_zone_for_break
 *   Given a break id, retrieves a string with the name of HV zone or zones affected
 *   by the order.
 *
 *   That HV zone name is:
 *     o The HV parent zone name if the affected zone is LV.
 *     o The HV ou ST zone name if the affected zone is HV or ST.
 *
 *   If a LV zone doesn't have a parent HV zone use the LV zone.
 *   If more than one zone is affected by the order, string as the different zones
 *   limited by 1',''.
 *
 */
FUNCTION hv_zone_for_break (p_break_id IN  po_int_elec_break.ID%TYPE) RETURN VARCHAR2 ;


/*
 * PROCEDURE hv_zone_for_property
 *   Given a property number, retrieves from a built customer in PowerOn the HV
 *   associated zone. The value is assigned to the OUT parameter.
 *
 *   That HV zone name is:
 *     o The HV parent zone name if a LV customer.
 *     o The HV zone name if a LH customer.
 *
 *   The output will have NULL if no HV zone is found.
 */
PROCEDURE hv_zone_for_property(p_property_no       IN  tvbpgisdetail.no_property%TYPE
                              ,p_cd_company_system IN tvbpgisdetail.cd_company_system%TYPE
                              ,p_hv_zone_name      OUT po_elec_zone.NAME%TYPE
							  ,p_simple_area_id    OUT po_customer.simple_area_id%TYPE    ) ;

/*
 * PROCEDURE comma_to_array
 *   Populates Oracle collection p_tab with the comma separated values in p_comma_string.
 *   The values are added to p_tab (existing values will be kept).
 */
PROCEDURE comma_to_array(p_comma_string IN  VARCHAR2
                        ,p_tab          IN OUT tbl_str) ;


/* FUNCTION upstream_transformer
 *   Returns the rwo_id3 of the upstream HV/LV transformer. Returns NULL if no transformer exists upstream.
 *   If p_break_id is the break id of a transformer, the upstream transformer will be returned, or most likely,
 *   NULL, as no upstream transformer should exist. If several transformers feed p_break_id only the rwo_id3
 *   of one transformer is randomly returned.
 */
FUNCTION upstream_transformer(p_break_id IN po_int_elec_break.ID%TYPE) RETURN NUMBER ;


/*
 * FUNCTION get_etr_feedback_for_order
 *   Returns a string that indicates the ETR value and if the user information is
 *   based on field information. Returns NULL if no information is available.
 */
FUNCTION get_etr_feedback_for_order(p_order_id IN po_order.ID%TYPE) RETURN VARCHAR2 ;


/*
 * PROCEDURE downstream_breaks_cod_sortable
 *   Wrapper procedure to call downstream_breaks_c from package ched_network_explorer.
 *   Similar to downstream_breaks_cod but supply points for the same parent are sorted by
 *   address.
 */
PROCEDURE downstream_breaks_cod_sortable(p_break_id     	 		IN  po_int_elec_break.ID%TYPE,
						                 p_no_customers 	   		IN  NUMBER := 0,
								         p_limit_to_break_zone 	IN NUMBER := 1,
                                         p_cursor       	   		OUT Ched_Utils.oms_cursor) ;


/*
 * FUNCTION sortable_address_for
 *   Returns the sortable address for p_break_id. If p_break_id is a service break
 *   (ie, a supply point) the function returns the sortable address of an associated customer.
 *   If no customer is associated with the supply point returns NULL. For all other breaks returns NULL.
 */
FUNCTION sortable_address_for(p_break_id IN po_int_elec_break.ID%TYPE) RETURN VARCHAR2 ;
PRAGMA RESTRICT_REFERENCES (sortable_address_for, WNDS, RNPS, WNPS);


/* FUNCTION first_interruption_for
 *   Returns the date of the first interruption for the order id given. Returns NULL for orders with
 *   no interruption (eg, IS orders or planned outages not started yet).
 */
FUNCTION first_interruption_for(p_order_id IN po_order.ID%TYPE) RETURN DATE ;

FUNCTION getVersion return varchar2;

$if OMS.CHED_UTILS_CFG.DEBUG_ACTIVE $then
   /* required during unit testing and development but not production*/

$END


PROCEDURE tce_get_feeder_tna(
    p_property_no       IN  tvbpgisdetail.no_property%TYPE
   ,p_cd_company_system IN  tvbpgisdetail.cd_company_system%TYPE
   ,p_hv_zone_name      OUT po_elec_zone.NAME%TYPE
   ,p_simple_area_id    OUT po_customer.simple_area_id%TYPE    )
;
END Ched_Utils ;

/


