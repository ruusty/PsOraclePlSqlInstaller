
  CREATE OR REPLACE PACKAGE BODY "OMS"."CHED_UTILS" IS

/*


Copyright (c) Ched Services 2010

 *
 * Purpose
 *   Aggregates functions/procedure related with incidents.
 *
 */
gr_VERSION CONSTANT VARCHAR2(200) := '4.3.0.0';

TYPE tbl_zone_name IS TABLE OF VARCHAR2(32) ;

-- Variable to hold the facility type id of the HV feeder.
g_hv_feeder_ft_id po_int_elec_break.facility_type_id%TYPE ;

-- Variable that identify the customer facility type id.
g_cust_conn_ft po_facility_type.ID%TYPE ;

-- Variable to hold the rwo_code for the stn_switch object.
g_stn_switch_rwo_code po_facility_type.gis_rwo_code%TYPE ;

-- Variable to hold the facility typeid for the HV/LV transformer.
g_hv_lv_transf_ft_id po_facility_type.ID%TYPE ;

-- Variable to hold the facility type id of the Stn Switch CB.
g_stn_switch_cb po_int_elec_break.facility_type_id%TYPE ;


/*
 * Function outage_head_location
 *   Given an incident returns the location of the latest outage head. Current and non-current
 *   outage heads are considered (useful to get the location for restored orders).
 *
 *   For outage with multi outage heads the latest is picked up (or randomly one if their
 *   timestamp is the same).
 */
FUNCTION outage_head_location(p_incident_id  IN NUMBER,
                              p_current_only IN NUMBER := 0) RETURN VARCHAR2 IS

  CURSOR c_out_head_loc IS
    SELECT B.location_desc, NE.executed_date
    FROM   po_outage_head OH,
           po_network_event NE,
           po_int_elec_break B
    WHERE  OH.incident_id = p_incident_id AND
           NE.ID          = OH.network_event_id AND
           B.ID           = NE.elec_break_id
    ORDER BY NE.executed_date DESC ;

    v_loc_desc  po_int_elec_break.location_desc%TYPE := NULL ;
    v_exec_date po_network_event.executed_date%TYPE := NULL ;

BEGIN
  --
  -- Note that the following works too if no data is found (NULL is returned).
  --
  OPEN c_out_head_loc ;
  FETCH c_out_head_loc INTO v_loc_desc, v_exec_date ;
  CLOSE c_out_head_loc ;

  RETURN v_loc_desc ;
END ;


/*
 * Procedure zones_for_type
 *   Parameter out p_ref_cursor is a cursor with the zones existing for the type given.
 *   Parameter p_business_code allows to filter the zones list by company. If NULL all
 *   zones will be shown. Valid values are '8000' for PAL and '9000' for CP.
 *   Proxy zones or zones with no normal span will not appear on the list.
 */
PROCEDURE zones_for_type(p_type          IN po_elec_zone.TYPE%TYPE,
                         p_business_code IN CHED_ORDER_EXT.business_code%TYPE,
                         p_ref_cursor    OUT oms_cursor) IS
BEGIN
  OPEN p_ref_cursor FOR
    SELECT ID, NAME
    FROM   ched_elec_zone
    WHERE  TYPE = p_type AND
           proxy_supplied_break_id IS NULL AND
           normal_span_id IS NOT NULL AND
           (business_code IS NULL OR
            business_code = p_business_code OR
            p_business_code IS NULL)
    ORDER BY NAME;
END ;


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
                               p_ref_cursor    OUT oms_cursor) IS
BEGIN
  OPEN p_ref_cursor FOR
    SELECT DISTINCT substation_name
    FROM   ched_elec_zone
    WHERE  TYPE = p_type AND
           proxy_supplied_break_id IS NULL AND
           normal_span_id IS NOT NULL AND
           (business_code IS NULL OR
            business_code = p_business_code OR
            p_business_code IS NULL)
    ORDER BY substation_name ;
END ;


/*
 * Procedure feeders_for_zone
 *   Parameter out p_ref_cursor is a cursor with the zones existing for the zone id given
 *   (p_zone_id).
 */
PROCEDURE feeders_for_zone(p_zone_id    IN po_elec_zone.ID%TYPE,
                           p_ref_cursor OUT oms_cursor) IS
BEGIN
  OPEN p_ref_cursor FOR
     SELECT DISTINCT b.ID,
           b.description,
           Ched_Utils.cod_dev_type(B.ID) AS devtype,
           DECODE (b.normal_state_c, 'closed', 1 ,0) AS naturalswitchstate,
           p_zone_id AS simpleparentkey,
           -1 AS issimple,
           p_zone_id AS parentkey,
           2 AS HIERARCHY,
           B.location_desc AS locationdesc,
           1 AS custcount,
           B.rwo_code AS rwoid,
           B.short_description AS alias,
           B.Switchable AS inline_switch,
           0 AS substn_under_inline_switch
    FROM   po_elec_zone Z,
           po_int_elec_span SP,
           po_elec_extent_to_section EXT_SECT,
           po_elec_adjacency A,
           po_int_elec_junction J,
           po_int_elec_break B
    WHERE  Z.ID                        = p_zone_id AND
           Z.normal_span_id            = SP.ID AND
           SP.extent_id                = EXT_SECT.extent_id AND
           EXT_SECT.network_section_id = A.network_section_id AND
           A.junction_id               = J.ID AND
           J.break_id                  = B.ID AND
           B.facility_type_id          = g_hv_feeder_ft_id
    ORDER BY b.description, B.short_description, B.location_desc;
END ;


/*
 * Function feeders_for_zone_ids
 *   Returns a comma separated string with the break ids for the feeders of the zone id given.
 */
FUNCTION feeders_for_zone_ids(p_zone_id IN po_elec_zone.ID%TYPE) RETURN VARCHAR2 IS

  v_feeder_ids VARCHAR2(512) := NULL ;

BEGIN
  FOR v_rec IN (SELECT DISTINCT b.ID
                FROM   po_elec_zone Z
                      ,po_int_elec_span SP
                      ,po_elec_extent_to_section EXT_SECT
                      ,po_elec_adjacency A
                      ,po_int_elec_junction J
                      ,po_int_elec_break B
                WHERE  Z.ID                        = p_zone_id
                  AND  Z.normal_span_id            = SP.ID
                  AND  SP.extent_id                = EXT_SECT.extent_id
                  AND  EXT_SECT.network_section_id = A.network_section_id
                  AND  A.junction_id               = J.ID
                  AND  J.break_id                  = B.ID
                  AND  B.facility_type_id          = g_hv_feeder_ft_id)
  LOOP
    IF v_feeder_ids IS NULL THEN
      v_feeder_ids := TO_CHAR(v_rec.ID) ;
    ELSE
      v_feeder_ids := v_feeder_ids || ',' || TO_CHAR(v_rec.ID) ;
    END IF ;
  END LOOP ;

  RETURN v_feeder_ids ;
END feeders_for_zone_ids ;


/*
 * Function stn_switches_cb_for_zone_ids
 *   Returns a comma separated string with the break ids for the Stn switches CB for the zone id given.
 */
FUNCTION stn_switches_cb_for_zone_ids(p_zone_id IN po_elec_zone.ID%TYPE) RETURN VARCHAR2 IS

  v_stn_switches_ids VARCHAR2(512) := NULL ;

BEGIN
  FOR v_rec IN (SELECT DISTINCT b.ID
                FROM   po_elec_zone Z
                      ,po_int_elec_span SP
                      ,po_elec_extent_to_section EXT_SECT
                      ,po_elec_adjacency A
                      ,po_int_elec_junction J
                      ,po_int_elec_break B
                WHERE  Z.ID                        = p_zone_id
                  AND  Z.normal_span_id            = SP.ID
                  AND  SP.extent_id                = EXT_SECT.extent_id
                  AND  EXT_SECT.network_section_id = A.network_section_id
                  AND  A.junction_id               = J.ID
                  AND  J.break_id                  = B.ID
                  AND  B.facility_type_id          = g_stn_switch_cb)
  LOOP
    IF v_stn_switches_ids IS NULL THEN
      v_stn_switches_ids := TO_CHAR(v_rec.ID) ;
    ELSE
      v_stn_switches_ids := v_stn_switches_ids || ',' || TO_CHAR(v_rec.ID) ;
    END IF ;
  END LOOP ;

  RETURN v_stn_switches_ids ;
END stn_switches_cb_for_zone_ids ;


/*
 * FUNCTION zone_for_break
 *   Returns the zone name for the given break (normal state). Returns NULL if the break
 *   doesn't exists. If the break is a tie break (ie, normally open and connected to two zones,
 *   one on each side) returns randomly one of the zones.
 */
FUNCTION zone_for_break(p_break_id IN po_int_elec_break.ID%TYPE) RETURN VARCHAR2 IS

  CURSOR c_zones_for_break IS
    SELECT DISTINCT Z.NAME, Z.TYPE, B.facility_type_id
    FROM   po_int_elec_junction J,
           po_elec_adjacency A,
           po_elec_extent_to_section EXT_SECT,
           po_int_elec_span SP,
           po_elec_zone Z,
           po_int_elec_break B
    WHERE  B.ID                 = p_break_id AND
           B.ID                 = J.break_id AND
           j.ID                 = A.junction_id AND
           A.network_section_id = EXT_SECT.network_section_id AND
           EXT_SECT.extent_id   = SP.extent_id AND
           SP.ID                = Z.normal_span_id AND
           Z.proxy_supplied_break_id IS NULL ;

  v_result_zone_name po_elec_zone.NAME%TYPE := NULL ;
  v_zone_name        po_elec_zone.NAME%TYPE := NULL ;
  v_ft_id            po_facility_type.ID%TYPE := NULL ;
  v_zone_type        po_elec_zone.TYPE%TYPE := NULL ;
  v_found            BOOLEAN := FALSE ;
  v_break_nc_id      po_network_classification.ID%TYPE ;
  v_nc_id            po_network_classification.ID%TYPE ;

BEGIN
  OPEN c_zones_for_break ;

  LOOP
    FETCH c_zones_for_break INTO v_zone_name, v_zone_type, v_ft_id ;
    EXIT WHEN c_zones_for_break%NOTFOUND ;

    IF NOT v_found THEN
      -- If nothing else matches, in terms of network classification,
      -- we return the first zone name obtained.
      v_result_zone_name := v_zone_name ;
      v_found := TRUE ;
    END IF ;

    --
    -- Get network classification id for the zone and break.
    --
    BEGIN
      SELECT network_classification_id
      INTO   v_break_nc_id
      FROM   po_facility_type
      WHERE  ID = v_ft_id ;

      SELECT ID
      INTO   v_nc_id
      FROM   po_network_classification
      WHERE  initials = v_zone_type ;

      IF v_break_nc_id = v_nc_id THEN
        v_result_zone_name := v_zone_name ;
        EXIT ;
      END IF ;

    EXCEPTION
      -- Just continue if one of these conditions is raised.
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN NULL ;
    END ;

  END LOOP ;

  CLOSE c_zones_for_break ;

  RETURN v_result_zone_name ;
END zone_for_break ;


/*
 * PROCEDURE zone_info_for_break
 *   Returns the zone name, id and normal span id for the zone associated with the break (normal state).
 *   Returns NULL if the break doesn't exists. If the break is a tie break (ie, normally open and
 *   connected to two zones, one on each side) returns randomly the information for one of the zones.
 */
PROCEDURE zone_info_for_break(p_break_id       IN  po_int_elec_break.ID%TYPE
                             ,p_zone_name      OUT po_elec_zone.NAME%TYPE
                             ,p_zone_id        OUT po_elec_zone.ID%TYPE
                             ,p_normal_span_id OUT po_elec_zone.ID%TYPE
                             ,p_zone_type      OUT po_elec_zone.TYPE%TYPE
                             ,p_subst_name     OUT po_elec_zone.SUBSTATION_NAME%TYPE) IS
  CURSOR c_zones_for_break IS
    SELECT DISTINCT Z.NAME, Z.TYPE, B.facility_type_id, Z.ID, Z.normal_span_id, NVL(I.inst_name, Z.substation_name)
    FROM   po_int_elec_junction J,
           po_elec_adjacency A,
           po_elec_extent_to_section EXT_SECT,
           po_int_elec_span SP,
           po_elec_zone Z,
           --!--> TD 2011/05/13. Use ched_installation table after LV zones removed.
           ched_int_elec_break_ext BE,
           ched_installation I,
           --!<-- TD 2011/05/13.
           po_int_elec_break B
    WHERE  B.ID                 = p_break_id AND
           --!--> TD 2011/05/13.
           I.id (+)             = BE.installation_id AND
           BE.break_id          = B.id AND
           --!<-- TD 2011/05/13.
           B.ID                 = J.break_id AND
           J.ID                 = A.junction_id AND
           A.network_section_id = EXT_SECT.network_section_id AND
           EXT_SECT.extent_id   = SP.extent_id AND
           SP.ID                = Z.normal_span_id AND
           Z.proxy_supplied_break_id IS NULL ;

  v_zone_name        po_elec_zone.NAME%TYPE := NULL ;
  v_zone_id          po_elec_zone.ID%TYPE := NULL ;
  v_normal_span_id   po_elec_zone.normal_span_id%TYPE := NULL ;
  v_ft_id            po_facility_type.ID%TYPE := NULL ;
  v_zone_type        po_elec_zone.TYPE%TYPE := NULL ;
  v_subst_name       po_elec_zone.SUBSTATION_NAME%TYPE := NULL ;
  v_found            BOOLEAN := FALSE ;
  v_break_nc_id      po_network_classification.ID%TYPE ;
  v_nc_id            po_network_classification.ID%TYPE ;

BEGIN
  OPEN c_zones_for_break ;

  LOOP
    FETCH c_zones_for_break INTO v_zone_name, v_zone_type, v_ft_id, v_zone_id, v_normal_span_id, v_subst_name ;
    EXIT WHEN c_zones_for_break%NOTFOUND ;

    IF NOT v_found THEN
      -- If nothing else matches, in terms of network classification,
      -- we return the first zone name obtained.
      p_zone_name      := v_zone_name ;
      p_zone_id        := v_zone_id ;
      p_normal_span_id := v_normal_span_id ;
      p_zone_type      := v_zone_type ;
      p_subst_name     := v_subst_name ;
      v_found := TRUE ;
    END IF ;

    --
    -- Get network classification id for the zone and break.
    --
    BEGIN
      SELECT network_classification_id
      INTO   v_break_nc_id
      FROM   po_facility_type
      WHERE  ID = v_ft_id ;

      SELECT ID
      INTO   v_nc_id
      FROM   po_network_classification
      WHERE  initials = v_zone_type ;

      IF v_break_nc_id = v_nc_id THEN
        p_zone_name      := v_zone_name ;
        p_zone_id        := v_zone_id ;
        p_normal_span_id := v_normal_span_id ;
        p_zone_type      := v_zone_type ;
        p_subst_name     := v_subst_name ;
        EXIT ;
      END IF ;

    EXCEPTION
      -- Just continue if one of these conditions is raised.
      WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN NULL ;
    END ;
  END LOOP ;

  CLOSE c_zones_for_break ;
END zone_info_for_break ;



/*
 * FUNCTION order_for_break
 *   Returns the reference label for the order associated with the break.
 *   Returns NULL if no order exists associated with the break.
 *   Note that a open break can have two outages (orders) associated (one on
 *   each side
 */
FUNCTION order_for_break(p_break_id IN po_int_elec_break.ID%TYPE) RETURN VARCHAR2 IS

  CURSOR c_zones_for_break IS
    SELECT DISTINCT O.reference_label
    FROM   po_int_elec_break B,
           po_int_elec_junction J,
           po_elec_adjacency A,
           po_elec_extent_to_section EXT_SECT,
           po_int_elec_span SP,
           po_order O
    WHERE  B.ID                 = p_break_id AND
           B.ID                 = J.break_id AND
           j.ID                 = A.junction_id AND
           A.network_section_id = EXT_SECT.network_section_id AND
           EXT_SECT.extent_id   = SP.extent_id AND
           SP.TYPE IN ('outage', 'predicted_outage') AND
           SP.owner_table_name  = 'po!incident' AND
           SP.owner_id          = O.incident_id ;

  v_ref_label po_order.reference_label%TYPE := NULL ;

BEGIN
  OPEN c_zones_for_break ;
  FETCH c_zones_for_break INTO v_ref_label ;
  CLOSE c_zones_for_break ;

  RETURN v_ref_label ;
END ;


/*
 * FUNCTION cod_dev_type
 *   Returns the device type according to device's rwo code.
 */
FUNCTION cod_dev_type(p_rwo_code IN NUMBER) RETURN NUMBER IS

 v_collection_name po_facility_type.collection_name%TYPE ;

BEGIN
  SELECT DISTINCT collection_name
  INTO   v_collection_name
  FROM   po_facility_type
  WHERE  gis_rwo_code = p_rwo_code ;

  IF v_collection_name = 'transformer' THEN
    RETURN 8 ;
  ELSIF v_collection_name = 'stn_switch' THEN
    RETURN 4;
  ELSIF v_collection_name = 'circuit_breaker' THEN
    RETURN 4;
  ELSIF v_collection_name = 'supply_point' THEN
    RETURN 12;
  ELSIF v_collection_name = 'po!customer_connection' THEN
    RETURN 16;
  ELSE
    RETURN 0 ;
  END IF ;

EXCEPTION
  -- By default returns 0.
  WHEN NO_DATA_FOUND THEN RETURN 0;
END cod_dev_type ;



/*
 * PROCEDURE downstream_breaks_cod
 *   Wrapper procedure to call downstream_breaks_c from package ched_network_explorer.
 *   Needed because VB has limitations on how to handle PL/SQL collections.
 */
PROCEDURE downstream_breaks_cod(p_break_id              IN  po_int_elec_break.ID%TYPE,
                                p_no_customers          IN  NUMBER := 0,
                                p_limit_to_break_zone   IN NUMBER := 1,
                                p_cursor                OUT Ched_Utils.oms_cursor) IS
BEGIN
   Ched_Network_Explorer.downstream_breaks_c(p_break_id, p_cursor, p_limit_to_break_zone, p_no_customers) ;

   OPEN p_cursor FOR
    SELECT
           NE.*,
           DECODE(B.transformer_isolator, NULL, 0, B.transformer_isolator) AS isNotSimple,
           cod_dev_type(NE.rwo_code) AS deviceType,
           NVL(b.STREET_NAME, '-') AS StreetName   --Only SP have Street_Name
    FROM
           CHED_NET_EXPLORER_RESULT NE,
           CHED_INT_ELEC_BREAK_EXT B
    WHERE
           NE.ID = B.BREAK_ID (+)
    ORDER BY
      ne.tree_level, DECODE(NE.rwo_code, g_stn_switch_rwo_code, -1, ne.seq_in_level) ;
END ;


/*
 * PROCEDURE downstream_stn_switch_cb
 *   Wrapper procedure to call downstream_breaks_c from package ched_network_explorer.
 *   The set returned will only include HV Station switches with function CB (ie, the feeders).
 *   Needed because VB has limitations on how to handle PL/SQL collections.
 */
PROCEDURE downstream_stn_switch_cb(p_break_id IN  po_int_elec_break.ID%TYPE,
                                   p_cursor   OUT Ched_Utils.oms_cursor) IS

  l_ft_ids ched_id_table := ched_id_table() ;

BEGIN
  --
  -- Note that 21 is the sub-code for Stn Switch that feeds the zone.
  --
  FOR v_rec IN (SELECT FT.ID
                FROM   po_facility_type FT,
                       po_network_classification NC
                WHERE  FT.collection_name           = 'stn_switch' AND
                       FT.sub_code                  = 21 AND
                       FT.network_classification_id = NC.ID AND
                       NC.initials                  = 'HV')
  LOOP
    l_ft_ids.EXTEND ;
    l_ft_ids(l_ft_ids.LAST) := ched_id(v_rec.ID) ;
  END LOOP ;

  Ched_Network_Explorer.downstream_breaks(p_break_id, 1, 1, l_ft_ids) ;

  OPEN p_cursor FOR SELECT ID,
                           description,
                           DECODE(state_c, 'closed', 5, 4) AS naturalSwitchState,
                           tree_level,
                           seq_in_level
                    FROM CHED_NET_EXPLORER_RESULT C
                    ORDER BY tree_level, seq_in_level ;
END downstream_stn_switch_cb ;


/*
 * FUNCTION downstream_stn_switch_cb_ids
 *   Returns a comma separated string with the break ids for the Stn Switches CB that
 *   are downstream the given break.
 */
FUNCTION downstream_stn_switch_cb_ids(p_break_id IN po_int_elec_break.ID%TYPE) RETURN VARCHAR2 IS

  v_id               CHED_NET_EXPLORER_RESULT.ID%TYPE ;
  v_description      CHED_NET_EXPLORER_RESULT.DESCRIPTION%TYPE ;
  v_nat_switch_state NUMBER(2) ;
  v_tree_level       CHED_NET_EXPLORER_RESULT.TREE_LEVEL%TYPE ;
  v_seq_in_level     CHED_NET_EXPLORER_RESULT.SEQ_IN_LEVEL%TYPE ;
  v_cursor_out       oms_cursor ;
  v_cb_ids           VARCHAR2(512) := NULL ;

BEGIN
  downstream_stn_switch_cb(p_break_id, v_cursor_out) ;

  LOOP
    FETCH v_cursor_out INTO v_id, v_description, v_nat_switch_state, v_tree_level, v_seq_in_level ;

    IF v_cursor_out%NOTFOUND THEN EXIT ; END IF ;

    IF v_cb_ids IS NULL THEN
      v_cb_ids := TO_CHAR(v_id) ;
    ELSE
      v_cb_ids := v_cb_ids || ',' || TO_CHAR(v_id) ;
    END IF ;
  END LOOP ;

  CLOSE v_cursor_out ;

  RETURN v_cb_ids ;
END downstream_stn_switch_cb_ids ;


/*
 * PROCEDURE upstream_breaks
 *   Helper proc defined to be called in Magik. Calls the procedure with the same name
 *   defined in ched_network_explorer.

 */
PROCEDURE upstream_breaks(p_break_id            IN  po_int_elec_break.ID%TYPE,
                          p_limit_to_break_zone IN  NUMBER := 0               ) IS
BEGIN
  ched_network_explorer.upstream_breaks(p_break_id, p_limit_to_break_zone) ;
END upstream_breaks ;


/*
 * Procedure customers_info
 *   Parameter out p_ref_cursor is a cursor with the customer information.
 */
PROCEDURE customers_info(p_break_id   IN po_int_elec_break.ID%TYPE,
                         p_ref_cursor OUT oms_cursor) IS

BEGIN
  Ched_Network_Explorer.downstream_breaks_c(p_break_id, p_ref_cursor, 0, 0) ;

  OPEN p_ref_cursor FOR
    SELECT NE.*,
           DECODE(B.transformer_isolator, NULL, 0, B.transformer_isolator) AS isNotSimple,
           CASE
             WHEN NE.rwo_code IS NULL AND NE.facility_type_id = 998 THEN 16
             ELSE Ched_Utils.cod_dev_type(NE.rwo_code)
           END AS deviceType,
           NE.ID AS customer_id,
           CCE.account_number AS accountNo,
           NVL(CCE.last_name, ' ') AS last_name,
           NVL(CCE.first_name, ' ') AS first_name,
           NVL(CCE.phone_number, ' ') AS phone,
           NVL(CT.NAME, ' ') AS revenue,
           DECODE(CT.ID,
                   1, 'Life',
                   2, 'Residential',
                   3, 'Industrial',
                   4, 'Industrial',
                   5, 'Industrial',
                   6, 'Commercial',
                   7, 'Industrial',
                   8, 'Industrial',
                   9, 'Industrial',
                  10, 'Industrial',
                  11, 'Industrial',
                  12, 'Residential',
                  'Industrial') AS connectionType,
           NVL(CCE.special_condition, ' ') AS special_con,
           NVL(CCE.description, ' ') AS cust_description,
           NVL(CCE.sortable_address, ' ') AS sort_description,
           NVL(CCE.premise_number, 0) AS NMI,
           NVL(CCE.postal_address, ' ') AS postal_address,
           NVL(CC.meter_number, ' ') AS MeterNo,
           CCE.move_in_date AS MoveInDate
    FROM   CHED_NET_EXPLORER_RESULT NE,
           ched_int_elec_break B,
           po_elec_demand D,
           po_customer_connection CC,
           ched_customer CCE,
           po_connection_type CT
    WHERE  NE.rwo_code            IS NULL
      AND  NE.facility_type_id    = g_cust_conn_ft
      AND  NE.ID                  = B.ID
      AND  NE.ID                  = D.demand_break_id
      AND  D.demand_section_id    = CC.demand_section_id
      AND  CC.customer_id         = CCE.ID
      AND  CC.connection_type_id  = CT.ID
    ORDER BY tree_level, seq_in_level;
END customers_info ;


/*
 * Procedure device_and_customers_info
 *   Parameter out p_ref_cursor is a cursor with the devices/customer information.
 */
PROCEDURE device_and_customers_info(p_break_id   IN po_int_elec_break.ID%TYPE,
                                    p_ref_cursor OUT oms_cursor) IS

BEGIN
  Ched_Network_Explorer.downstream_breaks_c(p_break_id, p_ref_cursor, 0, 0) ;

  OPEN p_ref_cursor FOR
    SELECT z.*, y.*
        FROM
            (
                SELECT NE.*,
                       NVL(b.STREET_NAME, '-') AS StreetName,   --Only SP have Street_Name
                       DECODE(B.transformer_isolator, NULL, 0, B.transformer_isolator) AS isNotSimple,
                       CASE
                        WHEN rwo_code IS NULL AND ne.facility_type_id = 998 THEN 16
                        ELSE Ched_Utils.cod_dev_type(NE.rwo_code) END deviceType
                FROM   CHED_NET_EXPLORER_RESULT NE,
                       CHED_INT_ELEC_BREAK_EXT B
                WHERE  NE.ID = B.BREAK_ID (+)) z,
            (
                SELECT DISTINCT(ner.ID) AS customer_ID,
                       CCE.ACCOUNT_NUMBER AS accountNo,
                       NVL(CCE.LAST_NAME, ' ') AS last_name,
                       NVL(CCE.FIRST_NAME, ' ') AS first_name,
                       NVL(CCE.PHONE_NUMBER, ' ') AS phone,
                       NVL(CT.NAME, ' ') AS revenue,
                       DECODE(CT.ID,
                                1, 'Life',
                                2, 'Residential',
                                3, 'Industrial',
                                4, 'Industrial',
                                5, 'Industrial',
                                6, 'Commercial',
                                7, 'Industrial',
                                8, 'Industrial',
                                9, 'Industrial',
                                10, 'Industrial',
                                11, 'Industrial',
                                12, 'Residential',
                                'Industrial') AS connectionType,
                       NVL(CCE.special_condition, ' ') AS special_con,
                       NVL(CCE.DESCRIPTION, ' ') AS cust_description,
                       NVL(CCE.sortable_address, ' ') AS sort_description,
                       NVL(CCE.PREMISE_NUMBER, 0) AS NMI,
                       NVL(CCE.postal_address, ' ') AS postal_address,
                       NVL(CCE.METER_BOX_KEY_NO, ' ') AS MeterNo,
                       CCE.MOVE_IN_DATE AS MoveInDate
                FROM   CHED_NET_EXPLORER_RESULT ner,
                       po_elec_demand D,
                       po_customer_connection CC,
                       ched_customer CCE,
                       po_connection_type CT
                WHERE  ner.rwo_code          IS NULL
                  AND  ner.facility_type_id  = g_cust_conn_ft
                  AND  NER.ID                = D.demand_break_id
                  AND  D.demand_section_id   = CC.demand_section_id
                  AND  CC.customer_id        = CCE.ID
                  AND  CC.connection_type_id = CT.ID ) y
       WHERE z.ID = y.customer_ID (+)
       ORDER BY tree_level, seq_in_level;

END device_and_customers_info ;


/*
 * Procedure device_and_cust_info_sorted
 *   Parameter out p_ref_cursor is a cursor with the devices/customer information sorted by
 *   tree level, parent, address (obtained only for supply points and customers) and sequence
 *   in the tree level.

2015-08-05 RGH  CR31844-Add Mobile Numbers to OMS COD PON
Added extra column phone_mobile. As this returns a ref cursor this should have no side effects

 */
PROCEDURE device_and_cust_info_sorted(p_break_id   IN po_int_elec_break.ID%TYPE,
                                      p_ref_cursor OUT oms_cursor) IS

BEGIN
  Ched_Network_Explorer.downstream_breaks_c(p_break_id, p_ref_cursor, 0, 0) ;

  OPEN p_ref_cursor FOR
    SELECT z.*, y.*
        FROM
            (
                SELECT NE.*,
                       NVL(b.STREET_NAME, '-') AS StreetName,   --Only SP have Street_Name
                       DECODE(B.transformer_isolator, NULL, 0, B.transformer_isolator) AS isNotSimple,
                       CASE
                        WHEN rwo_code IS NULL AND ne.facility_type_id = 998 THEN 16
                        ELSE Ched_Utils.cod_dev_type(NE.rwo_code) END deviceType,
                       sortable_address_for(NE.ID) AS sp_address
                FROM   CHED_NET_EXPLORER_RESULT NE,
                       CHED_INT_ELEC_BREAK_EXT B
                WHERE  NE.ID = B.BREAK_ID (+)) z,
            (
                SELECT DISTINCT(ner.ID) AS customer_ID,
                       CCE.ACCOUNT_NUMBER AS accountNo,
                       NVL(CCE.LAST_NAME, ' ') AS last_name,
                       NVL(CCE.FIRST_NAME, ' ') AS first_name,
                       NVL(CCE.PHONE_NUMBER, NVL(CCE.CELL_NUMBER, ' ')) AS phone,
                       NVL(CCE.CELL_NUMBER, ' ') AS phone_mobile,
                       NVL(CT.NAME, ' ') AS revenue,
                       DECODE(CT.ID,
                                1, 'Life',
                                2, 'Residential',
                                3, 'Industrial',
                                4, 'Industrial',
                                5, 'Industrial',
                                6, 'Commercial',
                                7, 'Industrial',
                                8, 'Industrial',
                                9, 'Industrial',
                                10, 'Industrial',
                                11, 'Industrial',
                                12, 'Residential',
                                'Industrial') AS connectionType,
                       NVL(CCE.special_condition, ' ') AS special_con,
                       NVL(CCE.DESCRIPTION, ' ') AS cust_description,
                       NVL(CCE.sortable_address, ' ') AS sort_description,
                       NVL(CCE.PREMISE_NUMBER, 0) AS NMI,
                       NVL(CCE.postal_address, ' ') AS postal_address,
                       NVL(CC.meter_number, ' ') AS MeterNo,
                       CCE.MOVE_IN_DATE AS MoveInDate
                FROM   CHED_NET_EXPLORER_RESULT ner,
                       po_elec_demand D,
                       po_customer_connection CC,
                       ched_customer CCE,
                       po_connection_type CT
                WHERE  ner.rwo_code          IS NULL
                  AND  ner.facility_type_id  = g_cust_conn_ft
                  AND  NER.ID                = D.demand_break_id
                  AND  D.demand_section_id   = CC.demand_section_id
                  AND  CC.customer_id        = CCE.ID
                  AND  CC.connection_type_id = CT.ID ) y
       WHERE z.ID = y.customer_ID (+)
       ORDER BY tree_level, parent_id, NVL(sort_description, sp_address) NULLS LAST, seq_in_level;

END device_and_cust_info_sorted ;


/*
 * Procedure device_and_wide_cust_info
 *   Parameter out p_ref_cursor is a cursor with the devices/customer information sorted by
 *   tree level, parent, address (obtained only for supply points and customers) and sequence
 *   in the tree level. This also includes all customers with a valid supply point and provisioning that
 *   are not in the CHED_CUSTOMER table.
2016-08-26 Simon Bond
 */
PROCEDURE device_and_wide_cust_info(p_break_id   IN po_int_elec_break.ID%TYPE,
                                    p_ref_cursor OUT oms_cursor) IS

BEGIN
  Ched_Network_Explorer.downstream_breaks_c(p_break_id, p_ref_cursor, 0, 0) ;

  OPEN p_ref_cursor FOR
  SELECT * FROM
    (SELECT z.*, y.*
        FROM

               ( SELECT NE.*,
                       NVL(b.STREET_NAME, '-') AS StreetName,   --Only SP have Street_Name
                       DECODE(B.transformer_isolator, NULL, 0, B.transformer_isolator) AS isNotSimple,
                       CASE
                        WHEN rwo_code IS NULL AND ne.facility_type_id = 998 THEN 16
                        ELSE Ched_Utils.cod_dev_type(NE.rwo_code) END deviceType,
                       sortable_address_for(NE.ID) AS sp_address
                FROM   CHED_NET_EXPLORER_RESULT NE,
                       CHED_INT_ELEC_BREAK_EXT B
                WHERE  NE.ID = B.BREAK_ID (+)) z,
            (
                SELECT DISTINCT(ner.ID) AS customer_ID,
                       TO_NUMBER(CCE.ACCOUNT_NUMBER) AS accountNo,
                       NVL(CCE.LAST_NAME, ' ') AS last_name,
                       NVL(CCE.FIRST_NAME, ' ') AS first_name,
                       NVL(CCE.PHONE_NUMBER, ' ') AS phone,
                       NVL(CT.NAME, ' ') AS revenue,
                       DECODE(CT.ID,
                                1, 'Life',
                                2, 'Residential',
                                3, 'Industrial',
                                4, 'Industrial',
                                5, 'Industrial',
                                6, 'Commercial',
                                7, 'Industrial',
                                8, 'Industrial',
                                9, 'Industrial',
                                10, 'Industrial',
                                11, 'Industrial',
                                12, 'Residential',
                                'Industrial') AS connectionType,
                       NVL(CCE.special_condition, ' ') AS special_con,
                       NVL(CCE.DESCRIPTION, ' ') AS cust_description,
                       NVL(CCE.sortable_address, ' ') AS sort_description,
                       NVL(CCE.PREMISE_NUMBER, 0) AS NMI,
                       NVL(CCE.postal_address, ' ') AS postal_address,
                       NVL(CCE.METER_BOX_KEY_NO, ' ') AS MeterNo,
                       CCE.MOVE_IN_DATE AS MoveInDate
                FROM   CHED_NET_EXPLORER_RESULT ner,
                       po_elec_demand D,
                       po_customer_connection CC,
                       ched_customer CCE,
                       po_connection_type CT
                WHERE  ner.rwo_code          IS NULL
                  AND  ner.facility_type_id  = g_cust_conn_ft
                  AND  NER.ID                = D.demand_break_id
                  AND  D.demand_section_id   = CC.demand_section_id
                  AND  CC.customer_id        = CCE.ID
                  AND  CC.connection_type_id = CT.ID
                  ) y
       WHERE z.ID = y.customer_ID (+)
       ORDER BY tree_level, parent_id, NVL(sort_description, sp_address) NULLS LAST, seq_in_level)
       union all
       select   /* Get the not quite right customers */
            TO_NUMBER(ner.SHORT_DESCRIPTION),
            ner.description as description,
            ner.short_description,
            ner.build_version,
            ner.dataset_name,
            ner.rwo_code,
            ner.rwo_id1,
            ner.rwo_id2,
            ner.rwo_id3,
            ner.main_world_x,
            ner.main_world_y,
            ner.location_desc,
            ner.simple_area_id,
            ner.phases,
            ner.normal_state_a,
            ner.normal_state_b,
            ner.normal_state_c,
            ner.state_a,
            ner.state_b,
            ner.state_c,
            ner.protective,
            ner.protection_enabled,
            ner.gang_operated,
            ner.switchable,
            ner.reclosable,
            ner.reclosing_enabled,
            ner.rebuild_change_type,
            ner.bypassed_a,
            ner.bypassed_b,
            ner.bypassed_c,
            ner.facility_type_id,
            ner.kva_rating_a,
            ner.kva_rating_b,
            ner.kva_rating_c,
            ner.tree_level,
            ner.seq_in_level,
            ner.id as parent_id,
            TAD.NM_STREET_1            AS StreetName,       /*Only SP have Street_Name*/
            0                          AS isNotSimple,
            16                         As deviceType,
            TAD.formatted_address      As sp_address,
            ner.id                     AS customer_ID,     /* NER ID will go here DISTINCT(ner.ID) AS customer_ID, */
            TO_NUMBER(gis.no_gis)      as accountNo,
            'The Occupant'             as last_name,
            ' '                        as first_name,
            ' '                        as phone,
            ' '                        as REVENUE,           
            'LIGHTSMAYBE'              as CONNECTIONTYPE,   /* This ensures the icon in the application is a question mark */
            ' '                        as SPECIAL_CON,
            'Unknown'                  as CUST_DESCRIPTION,
            tad.sortable_address       as SORT_DESCRIPTION, 
            sp.txt_nat_supp_point      as NMI,
            TAD.formatted_address      as POSTAL_ADDRESS,
            ' '                        as METERNO,
            sp.dt_start                as MOVEINDATE        /* moveindate not accurate, can't use null as it breaks the column sort in VB */
            FROM CHED_NET_EXPLORER_RESULT ner
                 inner join TVBPGISDETAIL gis on ner.SHORT_DESCRIPTION = gis.no_gis
                 join TVP056SERVPROV       sp on gis.cd_company_system = sp.cd_company_system and gis.no_property = sp.no_property and gis.no_serv_prov = sp.no_serv_prov          
                 left outer join tvp046property prop on sp.cd_company_system = prop.cd_company_system and prop.no_property = sp.no_property
                 left outer join CHED_SORTABLE_ADDRESS tad on sp.cd_company_system = tad.cd_company_system and prop.cd_address = tad.cd_address
                 where   sp.st_serv_prov not in ('R')                    /* Not Removed service provisions */
                 and     not exists (                                    /* Not in PowerOn */
                          select  null
                          from    po_customer c
                          where   c.premise_number = sp.txt_nat_supp_point);

END device_and_wide_cust_info;



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
                      p_err_code     OUT NUMBER) IS

  v_zone_name          po_elec_zone.NAME%TYPE ;
  v_zone_id            po_elec_zone.ID%TYPE ;
  v_normal_span_id     po_elec_zone.normal_span_id%TYPE ;
  v_zone_type          po_elec_zone.TYPE%TYPE ;
  v_subst_name         po_elec_zone.substation_name%TYPE ;
  v_upper_ns_id        po_int_elec_network_section.ID%TYPE ;
  v_upper_ls_id        po_int_elec_line_section.ID%TYPE ;
  v_upper_zone_name    po_elec_zone.NAME%TYPE ;
  v_source_junction_id po_int_elec_junction.ID%TYPE ;


  CURSOR c_source_junctions IS
    SELECT DISTINCT(J.ID) ID
    FROM   po_int_elec_span S,
           po_elec_extent_to_section ES,
           po_elec_adjacency A,
           po_int_elec_junction J
    WHERE  S.ID = v_normal_span_id AND
           ES.extent_id = S.extent_id AND
           A.network_section_id = ES.network_section_id AND
           J.ID = A.junction_id AND
           J.child_zone_id = v_zone_id ;

  CURSOR c_upper_zone_name IS
    SELECT DISTINCT Z.NAME
    FROM   po_elec_adjacency A,
           po_elec_extent_to_section EXT_SECT,
           po_int_elec_span S,
           po_elec_zone Z
    WHERE  A.line_section_id    = v_upper_ls_id AND
           A.network_section_id = EXT_SECT.network_section_id AND
           EXT_SECT.extent_id   = S.extent_id AND
           S.ID                 = Z.normal_span_id AND
           Z.proxy_supplied_break_id IS NULL ;

BEGIN
  p_hv_zone_name := NULL ;
  p_break_id     := NULL ;
  p_err_code     := -1 ;

  BEGIN
    SELECT ID
    INTO   p_break_id
    FROM   ched_int_elec_break
    WHERE  gis_id        = p_gis_id
      AND  build_version = 'master' ;

  EXCEPTION
    --
    -- GIS id unknown to PowerOn.
    --
    WHEN NO_DATA_FOUND THEN RETURN ;
  END ;

  --
  -- Get information about the zone associated with the customer's break.
  --
  zone_info_for_break(p_break_id, v_zone_name, v_zone_id, v_normal_span_id, v_zone_type, v_subst_name) ;

  IF v_zone_type = 'LV' THEN
    --
    -- Try to find the parent zone name.
    --
    OPEN c_source_junctions ;
    FETCH c_source_junctions INTO v_source_junction_id ;

    IF c_source_junctions%NOTFOUND THEN
      v_source_junction_id := NULL ;
    END IF ;

    CLOSE c_source_junctions ;

    IF v_source_junction_id IS NOT NULL THEN
      po_network_domain.upper_section_ids(v_source_junction_id, v_upper_ls_id, v_upper_ns_id) ;

      OPEN c_upper_zone_name ;
      FETCH c_upper_zone_name INTO v_upper_zone_name ;

      IF c_upper_zone_name%FOUND THEN
        p_hv_zone_name := v_upper_zone_name ;
        p_err_code     := 0 ;
      ELSE
        --
        -- No HV zone feeds the LV zone.
        --
        p_err_code     := -2 ;
      END IF ;

      CLOSE c_upper_zone_name ;
    ELSE
      --
      -- No HV zone feeds the LV zone.
      --
      p_err_code     := -2 ;
    END IF ;
  ELSIF v_zone_type = 'HV' THEN
    p_hv_zone_name := v_zone_name ;
    p_err_code     := 0 ;
  ELSE
    --
    -- Break belongs to a ST zone (the only zone level left).
    --
    p_err_code := -3 ;
  END IF ;
END hv_zone_for ;


FUNCTION hv_zone_for_break (p_break_id IN  po_int_elec_break.ID%TYPE) RETURN VARCHAR2 IS

  v_zone_name_tbl   tbl_zone_name := tbl_zone_name() ;
  v_hv_zone_names   VARCHAR2(256):= NULL ;
  v_zone_names      VARCHAR2(256):= NULL ;

  v_zone_name       po_elec_zone.NAME%TYPE ;

  v_index            PLS_INTEGER ;
  v_record_index     PLS_INTEGER := 1 ;
  v_current_position PLS_INTEGER := 1 ;


  --
  --  Add a zone to zone names table. Checks if the
  --  zone already exists.
  --
  PROCEDURE add_hv_zone(p_zone_name IN VARCHAR2) IS
    l_index PLS_INTEGER ;
    l_found BOOLEAN := FALSE ;
  BEGIN
    l_index := v_zone_name_tbl.FIRST ;

    WHILE l_index IS NOT NULL AND NOT l_found
    LOOP
      IF v_zone_name_tbl(l_index) = p_zone_name THEN
        l_found := TRUE ;
      END IF ;
      l_index := v_zone_name_tbl.NEXT(l_index) ;
    END LOOP ;

    IF NOT l_found THEN
      v_zone_name_tbl.EXTEND ;
      v_zone_name_tbl(v_zone_name_tbl.LAST) := p_zone_name ;
    END IF ;
  END add_hv_zone ;

  --
  --  Retreives the zone names from zone name table and builds
  --  a comma separeted string with ten.
  --
  PROCEDURE get_hv_zone IS
  BEGIN
    v_index := v_zone_name_tbl.FIRST ;

    WHILE v_index IS NOT NULL
    LOOP
      IF v_index = v_zone_name_tbl.FIRST THEN
        v_hv_zone_names := v_zone_name_tbl(v_index) ;
      ELSE
        v_hv_zone_names := v_hv_zone_names || ',' || v_zone_name_tbl(v_index) ;
      END IF ;
      v_index := v_zone_name_tbl.NEXT(v_index) ;
    END LOOP ;
  END get_hv_zone ;

  --
  -- Receives a zone and checks it's type. If a LV zone then gets
  -- the parent HV zone.
  --
  PROCEDURE deal_with_zone (p_zone_name po_elec_zone.NAME%TYPE) IS

    v_hv_zone_name     po_elec_zone.NAME%TYPE ;
    v_hv_zone_name_str VARCHAR2(512);
    v_found            BOOLEAN := FALSE;

    v_zone_id         po_elec_zone.ID%TYPE ;
    v_zone_type       po_elec_zone.TYPE%TYPE ;

    CURSOR c_upper_zone_name IS
    SELECT Z.NAME
      FROM CHED_ELEC_PARENT_ZONE PZ,
           po_elec_zone Z
    WHERE  PZ.zone_id = v_zone_id
      AND  PZ.parent_zone_id = Z.ID
      AND  Z.proxy_supplied_break_id IS NULL;

  BEGIN

    --
    -- Select zone information; make sure that only master zone is picked.
    --
    SELECT ID, TYPE
    INTO   v_zone_id, v_zone_type
    FROM   po_elec_zone
    WHERE  NAME = p_zone_name
      AND  proxy_supplied_break_id IS NULL
      AND  normal_span_id IS NOT NULL ;

    IF v_zone_type = 'LV' THEN
      --
      -- Try to find the parent zone name.
      --
      OPEN c_upper_zone_name ;
      LOOP
        FETCH c_upper_zone_name INTO v_hv_zone_name ;
        EXIT WHEN c_upper_zone_name%NOTFOUND;

        IF v_found THEN
          v_hv_zone_name_str := v_hv_zone_name_str || ', ' || v_hv_zone_name ;
        ELSE
          v_found := TRUE;
          v_hv_zone_name_str := v_hv_zone_name ;
        END IF;

      END LOOP;
      CLOSE c_upper_zone_name ;

      IF NOT v_found THEN
        v_hv_zone_name_str := p_zone_name ;
      END IF;

      --
      -- Add zone to table.
      --
      add_hv_zone(v_hv_zone_name_str);

  ELSE
    --
    -- Not a LV zone name. Add the zone name as it is.
    --
    add_hv_zone(p_zone_name);
  END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      add_hv_zone(p_zone_name);
  END deal_with_zone ;

 BEGIN

    v_zone_names := po_elec_network_info.zones_for_break(p_break_id);

  --
  --  Loop through string. Different zones are split by ', ' .
  --  For each zone find out it's type, If LV replace by parent HV zone.
  --  If no HV parent zone then use the LV.
  LOOP
    v_index := INSTR(v_zone_names, ',', v_current_position);

    IF v_index <> 0 THEN
       v_zone_name := SUBSTR(v_zone_names, v_current_position, v_index - v_current_position);

       deal_with_zone(v_zone_name);

       v_current_position := v_index + 2;
    ELSE
       deal_with_zone(SUBSTR(v_zone_names, v_current_position, LENGTH(v_zone_names)));
    END IF ;

    EXIT WHEN v_index = 0 OR v_index IS NULL ;
  END LOOP ;

  -- Get processed zones string.
  get_hv_zone ;

      IF v_hv_zone_names IS NULL THEN
        RETURN  v_zone_names;
      ELSE
        RETURN v_hv_zone_names;
      END IF;

END hv_zone_for_break;

/*

This is called from TCE to get a Feeder for a Trouble Call No Address (TNA)
Does not require the property to be built as part of the PowerOn Network

*/

PROCEDURE tce_get_feeder_tna(
    p_property_no       IN  tvbpgisdetail.no_property%TYPE
   ,p_cd_company_system IN  tvbpgisdetail.cd_company_system%TYPE
   ,p_hv_zone_name      OUT po_elec_zone.NAME%TYPE
   ,p_simple_area_id    OUT po_customer.simple_area_id%TYPE    )
IS
CURSOR feeder_cur IS
   select  Z.ID, Z.NAME feeder_name, Z.TYPE, IEB.SIMPLE_AREA_ID
from
 TVBPGISDETAIL G
 join oms.ched_int_elec_break_ext      e    on E.GIS_ID = G.NO_GIS
 join poweron.po_int_elec_break        ieb  on IEB.ID = E.BREAK_ID
 join poweron.po_int_elec_junction     junc on IEB.ID = JUNC.BREAK_ID and ieb.build_version = 'master'
 join po_elec_adjacency                adj  on ADJ.JUNCTION_ID = junc.id and adj.side = (select max(side) from PO_ELEC_ADJACENCY a where A.JUNCTION_ID = junc.ID)
 join po_int_elec_network_section      sect on ADJ.NETWORK_SECTION_ID = SEct.id
 join po_elec_zone                     z    on SECT.NORMAL_ZONE_ID = Z.ID
where
 G.NO_PROPERTY = p_property_no
 and g.cd_company_system = p_cd_company_system
;
BEGIN
   p_hv_zone_name   := NULL ;
   p_simple_area_id := NULL ;
   <<feeders>>
   FOR rec IN feeder_cur LOOP
      p_hv_zone_name    := rec.feeder_name;
      p_simple_area_id  := rec.SIMPLE_AREA_ID;
      EXIT feeders; -- Can only be 1
   END LOOP;
END;


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
                              ,p_simple_area_id    OUT po_customer.simple_area_id%TYPE    ) IS

  --
  -- Note that we sort by zone to ensure the order received, although the same property
  -- shouldn't be associated with customers of different tension levels.
  --
  CURSOR c_associated_zone_ids IS
    SELECT DISTINCT Z.ID, Z.NAME, Z.TYPE, CE.simple_area_id, DECODE(Z.TYPE, 'HV', 1, 'LV', 2, 'ST', 3, 4) ord_num
    FROM   ched_customer CE
          ,po_customer_connection CC
          ,po_elec_demand D
          ,po_int_elec_junction J
          ,po_elec_adjacency A
          ,po_elec_extent_to_section EXT_SECT
          ,po_int_elec_span S
          ,po_elec_zone Z
    WHERE  CE.no_property              = p_property_no
      AND  CE.cd_company_system        = p_cd_company_system
      AND  CC.customer_id              = CE.ID
      AND  D.demand_section_id         = CC.demand_section_id
      AND  J.break_id                  = D.demand_break_id
      AND  A.junction_id               = J.ID
      AND  EXT_SECT.network_section_id = A.network_section_id
      AND  S.extent_id                 = EXT_SECT.extent_id
      AND  Z.normal_span_id            = S.ID
      AND  Z.proxy_supplied_break_id IS NULL
    ORDER BY DECODE(Z.TYPE, 'HV', 1, 'LV', 2, 'ST', 3, 4) ;

  CURSOR c_parent_zones(p_zone_id po_elec_zone.ID%TYPE) IS
    SELECT Z.NAME
    FROM   CHED_ELEC_PARENT_ZONE PZ
          ,po_elec_zone Z
    WHERE  PZ.zone_id = p_zone_id
      AND  Z.ID       = PZ.parent_zone_id
      AND  Z.TYPE     = 'HV'
      AND  Z.normal_span_id IS NOT NULL
      AND  Z.proxy_supplied_break_id IS NULL ;

BEGIN
  p_hv_zone_name   := NULL ;
  p_simple_area_id := NULL ;

  FOR v_rec IN c_associated_zone_ids
  LOOP
    IF v_rec.TYPE = 'HV' THEN
      p_hv_zone_name   := v_rec.NAME ;
      p_simple_area_id := v_rec.simple_area_id ;
      RETURN ;
    END IF ;

    FOR v_parent_rec IN c_parent_zones(v_rec.ID)
    LOOP
      --
      -- Simple area id is always obtained from the customer.
      --
      p_hv_zone_name   := v_parent_rec.NAME ;
      p_simple_area_id := v_rec.simple_area_id ;
      RETURN ;
    END LOOP ;
  END LOOP ;

  RETURN ;
END hv_zone_for_property ;


/*
 * PROCEDURE comma_to_array
 *   Populates Oracle collection p_tab with the comma separated values in p_comma_string.
 *   The values are added to p_tab (existing values will be kept).
 */
PROCEDURE comma_to_array(p_comma_string IN  VARCHAR2
                        ,p_tab          IN OUT tbl_str) IS

  l_index            PLS_INTEGER;      -- used for parsing the comma delimited string
  l_record_index     PLS_INTEGER := 1; -- indexing for the array
  l_current_position PLS_INTEGER := 1; -- index for the string
  l_record           VARCHAR2(512);

BEGIN
  LOOP
    --
    -- Loop to get all values but the last.
    --
    l_index := INSTR( p_comma_string, ',', l_current_position) ;

    -- if l_index is null, the expression is evaluated to false.
    IF l_index <> 0
    THEN
      l_record := SUBSTR(p_comma_string, l_current_position, l_index - l_current_position);

      p_tab.EXTEND;
      p_tab(p_tab.LAST) := l_record;

      l_current_position := l_index + 1;
    END IF;

    EXIT WHEN l_index = 0 OR l_index IS NULL;
  END LOOP;

  l_record := SUBSTR(p_comma_string, l_current_position, LENGTH(p_comma_string) - l_current_position + 1);
  p_tab.EXTEND;
  p_tab(p_tab.LAST) := l_record;
END comma_to_array;


/* FUNCTION upstream_transformer
 *   Returns the rwo_id3 of the upstream HV/LV transformer. Returns NULL if no transformer exists upstream.
 *   If p_break_id is the break id of a transformer, the upstream transformer will be returned, or most likely,
 *   NULL, as no upstream transformer should exist. If several transformers feed p_break_id only the rwo_id3
 *   of one transformer is randomly returned.
 */
FUNCTION upstream_transformer(p_break_id IN po_int_elec_break.ID%TYPE) RETURN NUMBER IS

  CURSOR c_upstream_transfs IS
    SELECT NER.rwo_id3
    FROM   CHED_NET_EXPLORER_RESULT NER
    ORDER BY NER.tree_level ;

  v_rwo_id3 CHED_NET_EXPLORER_RESULT.rwo_id3%TYPE ;

BEGIN
  --
  -- The id of the HV/LV transformer should be known. Anyway, protect against that.
  --
  IF g_hv_lv_transf_ft_id IS NULL THEN
    RETURN NULL ;
  END IF ;

  --
  -- Get the transformers upstream.
  --
  ched_network_explorer.upstream_breaks(p_break_id, 0, 1, ched_id_table(ched_id(g_hv_lv_transf_ft_id))) ;

  --
  -- Select the closest (anyway, only one should exist).
  --
  OPEN c_upstream_transfs ;
  FETCH c_upstream_transfs INTO v_rwo_id3 ;

  IF c_upstream_transfs%NOTFOUND THEN
    CLOSE c_upstream_transfs ;
    RETURN NULL ;
  END IF ;

  CLOSE c_upstream_transfs ;

  RETURN v_rwo_id3 ;
END upstream_transformer ;


/*
 * FUNCTION get_etr_feedback_for_order
 *   Returns a string that indicates the ETR value and if the user information is
 *   based on field information. Returns NULL if no information is available.
 */
FUNCTION get_etr_feedback_for_order(p_order_id IN po_order.ID%TYPE) RETURN VARCHAR2 IS
  v_etr_date         po_etr.ETR%TYPE := NULL ;
  v_etr_field        po_etr.CONFIRMED%TYPE := NULL ;
  v_feedback         VARCHAR2 (50) := '';

BEGIN
  SELECT E.etr, E.confirmed
  INTO   v_etr_date, v_etr_field
  FROM   po_order O
        ,po_etr E
  WHERE  O.ID          = p_order_id
    AND  O.INCIDENT_ID = E.INCIDENT_ID;

  IF v_etr_date IS NOT NULL THEN
    v_feedback := 'ETR ' || TO_CHAR(v_etr_date,'DD-MON-YYYY HH24:MI') ;
  END IF;

  IF v_etr_field = 1 THEN
    v_feedback := v_feedback || ' (Field Information)' ;
  END IF;

  RETURN v_feedback ;

EXCEPTION
  -- Just continue if one of these conditions is raised.
  WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN RETURN '' ;
END get_etr_feedback_for_order ;


/*
 * FUNCTION sortable_address_for
 *   Returns the sortable address for p_break_id. If p_break_id is a service break
 *   (ie, a supply point) the function returns the sortable address of an associated customer.
 *   If no customer is associated with the supply point returns NULL. For all other breaks returns NULL.
 */
FUNCTION sortable_address_for(p_break_id IN po_int_elec_break.ID%TYPE) RETURN VARCHAR2 IS

  CURSOR c_sortable_address IS
    SELECT DISTINCT
            ED.service_break_id
           ,first_value(sortable_address) OVER (PARTITION BY ED.service_break_id ORDER BY C.sortable_address) AS sortable_address
    FROM    ched_customer C
           ,po_customer_connection CC
           ,po_elec_demand ED
    WHERE  ED.service_break_id  = p_break_id
      AND  CC.demand_section_id = ED.demand_section_id
      AND  C.ID                 = CC.customer_id ;

  v_service_break_id po_elec_demand.service_break_id%TYPE := NULL ;
  v_address          ched_customer.sortable_address%TYPE := NULL ;

BEGIN
  OPEN c_sortable_address ;
  FETCH c_sortable_address INTO v_service_break_id, v_address ;
  CLOSE c_sortable_address ;

  RETURN v_address ;
END sortable_address_for ;


/*
 * PROCEDURE downstream_breaks_cod_sortable
 *   Wrapper procedure to call downstream_breaks_c from package ched_network_explorer.
 *   Similar to downstream_breaks_cod but supply points for the same parent are sorted by
 *   address.
 */
PROCEDURE downstream_breaks_cod_sortable(p_break_id                 IN  po_int_elec_break.ID%TYPE,
                                         p_no_customers             IN  NUMBER := 0,
                                         p_limit_to_break_zone  IN NUMBER := 1,
                                         p_cursor                   OUT Ched_Utils.oms_cursor) IS
BEGIN
   Ched_Network_Explorer.downstream_breaks_c(p_break_id, p_cursor, p_limit_to_break_zone, p_no_customers) ;

   OPEN p_cursor FOR
    SELECT
           NE.*,
           DECODE(B.transformer_isolator, NULL, 0, B.transformer_isolator) AS isNotSimple,
           cod_dev_type(NE.rwo_code) AS deviceType,
           NVL(b.STREET_NAME, '-') AS StreetName,   --Only SP have Street_Name
           sortable_address_for(NE.ID) AS sortable_address
    FROM
           CHED_NET_EXPLORER_RESULT NE,
           CHED_INT_ELEC_BREAK_EXT B
    WHERE
           NE.ID = B.BREAK_ID (+)
    ORDER BY
      ne.tree_level, DECODE(NE.rwo_code, g_stn_switch_rwo_code, -1, 0), NE.parent_id, sortable_address_for(NE.ID) NULLS LAST, ne.seq_in_level ;
END downstream_breaks_cod_sortable ;


/* FUNCTION first_interruption_for
 *   Returns the date for the first interruption for the order id given. Returns _unset for with
 *   no interruption (eg, IS orders or planned outages not started yet).
 */
FUNCTION first_interruption_for(p_order_id IN po_order.ID%TYPE) RETURN DATE IS

  CURSOR c_first_interruption IS
    SELECT time_deenergized
    FROM   po_order O
          ,po_deenergization D
    WHERE  O.ID          = p_order_id
      AND  D.incident_id = O.incident_id
    ORDER BY time_deenergized ;

  v_interruption po_deenergization.time_deenergized%TYPE := NULL ;

BEGIN
  OPEN c_first_interruption ;
  FETCH c_first_interruption INTO v_interruption ;

  IF c_first_interruption%FOUND THEN
    CLOSE c_first_interruption ;
    RETURN v_interruption ;
  END IF ;

  CLOSE c_first_interruption ;

  RETURN NULL ;
END first_interruption_for ;

FUNCTION getVersion return varchar2
IS
begin
    return gr_VERSION;
end getVersion;

BEGIN
  /*
   * Get the rwo_code for the stn_switch.
   */
  BEGIN
    SELECT gis_rwo_code
    INTO   g_stn_switch_rwo_code
    FROM   po_facility_type
    WHERE  collection_name = 'stn_switch'
      AND  network_classification_id IS NOT NULL
      AND  ROWNUM = 1 ;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN g_stn_switch_rwo_code := NULL ;
  END ;

  /*
   * Get the facility type for the HV/LV transformer.
   */
  BEGIN
    SELECT FT.ID
    INTO   g_hv_lv_transf_ft_id
    FROM   po_facility_type FT
          ,po_network_classification NC
    WHERE  FT.collection_name = 'transformer'
      AND  NC.ID              = FT.network_classification_id
      AND  NC.initials        = 'HV'
      AND  ROWNUM             = 1 ;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN g_hv_lv_transf_ft_id := NULL ;
  END ;

  /*
   * Get the facility type id from the name. Will be executed once per session at load time.
   */
  SELECT ID
  INTO   g_hv_feeder_ft_id
  FROM   po_facility_type FT
  WHERE  FT.NAME = 'HV Feeder' ;

  /*
   * Get the facility type id for the Stn Switches CB.
   */
  SELECT FT.ID
  INTO   g_stn_switch_cb
  FROM   po_facility_type FT
        ,po_network_classification NC
  WHERE  FT.collection_name           = 'stn_switch'
    AND  FT.sub_code                  = 21
    AND  FT.network_classification_id = NC.ID
    AND  NC.initials                  = 'HV' ;

  /*
   * Set the value for the variable that identify the customer connection.
   * Not protected code, as it must exist.
   */
  SELECT ID
  INTO   g_cust_conn_ft
  FROM   po_facility_type
  WHERE  collection_name = 'po!customer_connection' ;

END Ched_Utils ;
/


