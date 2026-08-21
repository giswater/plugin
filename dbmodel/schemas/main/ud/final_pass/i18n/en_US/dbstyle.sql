/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'Fluid Type Lines', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.40.9-Bratislava">
  <renderer-v2 symbollevels="0" enableorderby="0" type="RuleRenderer" referencescale="-1" forceraster="0">
    <rules key="{0636f35c-7cdb-4ac1-935d-1cf79c89bfa5}">
      <rule symbol="0" label="FLUID TYPE" key="{ecd5686e-b0b0-4a8a-867a-3e881ff055ed}">
        <rule filter="&quot;fluid_type&quot; = ''0''" symbol="1" label="''0''" key="{40e8c9c5-e496-4f35-8c10-e31f6d62aba8}"/>
        <rule filter="&quot;fluid_type&quot; = ''1''" symbol="2" label="''1''" key="{4a15a529-2726-4994-8c68-89318c76da72}"/>
        <rule filter="&quot;fluid_type&quot; = ''2''" symbol="3" label="''2''" key="{35abe4e2-8068-4788-88ad-ad882466bca2}"/>
        <rule filter="&quot;fluid_type&quot; = ''3''" symbol="4" label="''3''" key="{a9358e41-776d-4a35-a01f-d1239b85409f}"/>
        <rule filter="&quot;fluid_type&quot; = ''4''" symbol="5" label="''4''" key="{6932aaa4-244a-48eb-89c8-0eb1ff750952}"/>
      </rule>
      <rule filter="initoverflowpath IS FALSE" symbol="6" label="Initoverflowpath FALSE" key="{997a52d5-68d3-4988-8274-c9a9ad97ae73}"/>
      <rule filter="initoverflowpath IS TRUE" symbol="7" label="Initoverflowpath TRUE" key="{53702b46-77ae-48dc-87cb-adc8d9b4d459}"/>
    </rules>
    <symbols>
      <symbol force_rhr="0" frame_rate="10" name="0" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{82d77555-fd1a-4c4b-9dfb-6cf4f89043ea}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="223,0,255,0,hsv:0.8125,1,1,0" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="1" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{e27969d7-935c-44dd-b635-1762befd319c}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="0,236,255,255,rgb:0,0.92549019607843142,1,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="2" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{f5733214-6984-4124-9c69-b801dad5db3d}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="204,163,0,255,rgb:0.80000000000000004,0.63921568627450975,0,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="3" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{c48c11c7-7bb9-4b99-8b87-f1ba495dbaca}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="255,0,0,255,rgb:1,0,0,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="4" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{1faa0c62-4b21-408e-8118-b4d46d1e1f83}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="255,0,242,255,rgb:1,0,0.94901960784313721,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="5" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{dcfa2132-2ed5-4aef-8162-caa7823b95bd}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="0,255,76,255,rgb:0,1,0.29803921568627451,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="1.66" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="6" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{22a8834d-18a7-497b-92ee-d4d461063da0}" locked="0" enabled="1" class="MarkerLine">
          <Option type="Map">
            <Option name="average_angle_length" value="4" type="QString"/>
            <Option name="average_angle_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="average_angle_unit" value="MM" type="QString"/>
            <Option name="interval" value="3" type="QString"/>
            <Option name="interval_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="interval_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_along_line" value="0" type="QString"/>
            <Option name="offset_along_line_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_along_line_unit" value="MM" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="place_on_every_part" value="true" type="bool"/>
            <Option name="placements" value="Interval" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="rotate" value="1" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
          <symbol force_rhr="0" frame_rate="10" name="@6@0" alpha="1" is_animated="0" type="marker" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" value="" type="QString"/>
                <Option name="properties"/>
                <Option name="type" value="collection" type="QString"/>
              </Option>
            </data_defined_properties>
            <layer pass="0" id="{6d54d628-e447-4f9b-aa18-854b2fc7a132}" locked="0" enabled="1" class="SimpleMarker">
              <Option type="Map">
                <Option name="angle" value="0" type="QString"/>
                <Option name="cap_style" value="square" type="QString"/>
                <Option name="color" value="0,0,0,255,hsv:0.63749999999999996,0.5077744716563668,0,1" type="QString"/>
                <Option name="horizontal_anchor_point" value="1" type="QString"/>
                <Option name="joinstyle" value="bevel" type="QString"/>
                <Option name="name" value="circle" type="QString"/>
                <Option name="offset" value="0,0" type="QString"/>
                <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="offset_unit" value="MM" type="QString"/>
                <Option name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString"/>
                <Option name="outline_style" value="solid" type="QString"/>
                <Option name="outline_width" value="0" type="QString"/>
                <Option name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="outline_width_unit" value="MM" type="QString"/>
                <Option name="scale_method" value="diameter" type="QString"/>
                <Option name="size" value="1.5" type="QString"/>
                <Option name="size_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="size_unit" value="MM" type="QString"/>
                <Option name="vertical_anchor_point" value="1" type="QString"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" value="" type="QString"/>
                  <Option name="properties"/>
                  <Option name="type" value="collection" type="QString"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol force_rhr="0" frame_rate="10" name="7" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{3d948eb9-9960-4238-9138-1757f13eaeee}" locked="0" enabled="1" class="MarkerLine">
          <Option type="Map">
            <Option name="average_angle_length" value="4" type="QString"/>
            <Option name="average_angle_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="average_angle_unit" value="MM" type="QString"/>
            <Option name="interval" value="3" type="QString"/>
            <Option name="interval_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="interval_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_along_line" value="0" type="QString"/>
            <Option name="offset_along_line_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_along_line_unit" value="MM" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="place_on_every_part" value="true" type="bool"/>
            <Option name="placements" value="Interval" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="rotate" value="1" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
          <symbol force_rhr="0" frame_rate="10" name="@7@0" alpha="1" is_animated="0" type="marker" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" value="" type="QString"/>
                <Option name="properties"/>
                <Option name="type" value="collection" type="QString"/>
              </Option>
            </data_defined_properties>
            <layer pass="0" id="{2675b728-5ff3-49a7-9855-100d997df1fc}" locked="0" enabled="1" class="SimpleMarker">
              <Option type="Map">
                <Option name="angle" value="0" type="QString"/>
                <Option name="cap_style" value="square" type="QString"/>
                <Option name="color" value="255,255,255,255,hsv:0,0,1,1" type="QString"/>
                <Option name="horizontal_anchor_point" value="1" type="QString"/>
                <Option name="joinstyle" value="bevel" type="QString"/>
                <Option name="name" value="circle" type="QString"/>
                <Option name="offset" value="0,0" type="QString"/>
                <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="offset_unit" value="MM" type="QString"/>
                <Option name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString"/>
                <Option name="outline_style" value="solid" type="QString"/>
                <Option name="outline_width" value="0" type="QString"/>
                <Option name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="outline_width_unit" value="MM" type="QString"/>
                <Option name="scale_method" value="diameter" type="QString"/>
                <Option name="size" value="1.5" type="QString"/>
                <Option name="size_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
                <Option name="size_unit" value="MM" type="QString"/>
                <Option name="vertical_anchor_point" value="1" type="QString"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" value="" type="QString"/>
                  <Option name="properties"/>
                  <Option name="type" value="collection" type="QString"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option name="name" value="" type="QString"/>
        <Option name="properties"/>
        <Option name="type" value="collection" type="QString"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol force_rhr="0" frame_rate="10" name="" alpha="1" is_animated="0" type="line" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" value="" type="QString"/>
            <Option name="properties"/>
            <Option name="type" value="collection" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" id="{e56f016d-a2d7-4934-8012-09784c514d01}" locked="0" enabled="1" class="SimpleLine">
          <Option type="Map">
            <Option name="align_dash_pattern" value="0" type="QString"/>
            <Option name="capstyle" value="square" type="QString"/>
            <Option name="customdash" value="5;2" type="QString"/>
            <Option name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="customdash_unit" value="MM" type="QString"/>
            <Option name="dash_pattern_offset" value="0" type="QString"/>
            <Option name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="dash_pattern_offset_unit" value="MM" type="QString"/>
            <Option name="draw_inside_polygon" value="0" type="QString"/>
            <Option name="joinstyle" value="bevel" type="QString"/>
            <Option name="line_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString"/>
            <Option name="line_style" value="solid" type="QString"/>
            <Option name="line_width" value="0.26" type="QString"/>
            <Option name="line_width_unit" value="MM" type="QString"/>
            <Option name="offset" value="0" type="QString"/>
            <Option name="offset_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="offset_unit" value="MM" type="QString"/>
            <Option name="ring_filter" value="0" type="QString"/>
            <Option name="trim_distance_end" value="0" type="QString"/>
            <Option name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_end_unit" value="MM" type="QString"/>
            <Option name="trim_distance_start" value="0" type="QString"/>
            <Option name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
            <Option name="trim_distance_start_unit" value="MM" type="QString"/>
            <Option name="tweak_dash_pattern_on_corners" value="0" type="QString"/>
            <Option name="use_custom_dash" value="0" type="QString"/>
            <Option name="width_map_unit_scale" value="3x:0,0,0,0,0,0" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" value="" type="QString"/>
              <Option name="properties"/>
              <Option name="type" value="collection" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>1</layerGeometryType>
</qgis>
')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'Treatment Type Points', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.40.9-Bratislava" styleCategories="Symbology">
  <renderer-v2 referencescale="-1" enableorderby="0" forceraster="0" type="RuleRenderer" symbollevels="0">
    <rules key="{dac19cc9-4af1-4434-bc56-f502f25f3739}">
      <rule key="{42be5776-4699-4c86-9b02-1ee917bb3ced}" symbol="0" filter="has_treatment IS TRUE" label="Has Treatment TRUE"/>
      <rule key="{efe3866a-f237-4452-a294-f2f81389df04}" symbol="1" filter="has_treatment is FALSE" label="Has Treatment FALSE"/>
      <rule key="{ec6be30c-1a3e-4176-a82e-fe53fb7fb9f7}" symbol="2" label="TREATMENT TYPE">
        <rule key="{a7eabcc8-1387-42d7-9dd6-68a3a6c849d7}" symbol="3" filter="&quot;treatment_type&quot; = ''0''" label="NOT INFORMED"/>
        <rule key="{54611c8e-dd38-468d-b573-1945f2fe7d78}" symbol="4" filter="&quot;treatment_type&quot; = ''1''" label="TREATED"/>
        <rule key="{7011522c-0b6a-412b-aff5-20dbd5c7c70e}" symbol="5" filter="&quot;treatment_type&quot; = ''2''" label="PRETREATED"/>
        <rule key="{91907c13-ae5a-4e5e-a553-74305c272033}" symbol="6" filter="&quot;treatment_type&quot; = ''3''" label="NOT TREATED"/>
      </rule>
    </rules>
    <symbols>
      <symbol force_rhr="0" name="0" alpha="1" frame_rate="10" type="marker" is_animated="0" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" pass="0" locked="0" class="SimpleMarker" id="{9ce795f0-98ba-42b8-87f5-df434f2f074d}">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="84,176,74,255,rgb:0.32941176470588235,0.69019607843137254,0.29019607843137257,1" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="61,128,53,255,rgb:0.23921568627450981,0.50196078431372548,0.20784313725490197,1" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0.4" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="4" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" name="1" alpha="1" frame_rate="10" type="marker" is_animated="0" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" pass="0" locked="0" class="SimpleMarker" id="{565d931c-fbf2-43c1-ad04-9f17595bf5c0}">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="60,76,219,255,hsv:0.65000000000000002,0.72538338292515447,0.85882352941176465,1" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="128,17,25,0,rgb:0.50196078431372548,0.06666666666666667,0.09803921568627451,0" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0.4" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="4" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" name="2" alpha="1" frame_rate="10" type="marker" is_animated="0" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" pass="0" locked="0" class="SimpleMarker" id="{ac1c0502-1ad3-43e1-b983-d35d88d6f381}">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="164,113,88,0,rgb:0.64313725490196083,0.44313725490196076,0.34509803921568627,0" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="35,35,35,0,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,0" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" name="3" alpha="1" frame_rate="10" type="marker" is_animated="0" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" pass="0" locked="0" class="SimpleMarker" id="{569ee005-4ee6-448d-83c7-d8d4472d923c}">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="0,208,213,255,hsv:0.50416666666666665,1,0.83529411764705885,1" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" name="4" alpha="1" frame_rate="10" type="marker" is_animated="0" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" pass="0" locked="0" class="SimpleMarker" id="{a2f69651-9bd8-46da-8350-a92be411c633}">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="211,145,113,255,hsv:0.05483333333333333,0.46341649500267035,0.82572671091783012,1" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" name="5" alpha="1" frame_rate="10" type="marker" is_animated="0" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" pass="0" locked="0" class="SimpleMarker" id="{f9b8c1b9-4944-42d2-a883-5212715f55f5}">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="222,0,0,255,hsv:0,1,0.87136644541084918,1" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" name="6" alpha="1" frame_rate="10" type="marker" is_animated="0" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" pass="0" locked="0" class="SimpleMarker" id="{05be1bcf-336c-49db-9f01-b701889ec353}">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="202,0,197,255,hsv:0.83750000000000002,1,0.79253833829251541,1" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol force_rhr="0" name="" alpha="1" frame_rate="10" type="marker" is_animated="0" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" pass="0" locked="0" class="SimpleMarker" id="{d9631284-8847-4256-a58c-20d442a69fe0}">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="255,0,0,255,rgb:1,0,0,1" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>
')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'audit_psector_arc_traceability', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.28.4-Firenze" styleCategories="Symbology">
  <renderer-v2 symbollevels="0" referencescale="-1" type="RuleRenderer" enableorderby="0" forceraster="0">
    <rules key="{7d5582c5-3691-4ba7-8a97-b8a2ef4beafb}">
      <rule filter=" &quot;action&quot;= ''Execute psector'' AND &quot;psector_state&quot;=0 AND (&quot;addparam&quot; IS NULL OR &quot;addparam&quot; NOT LIKE ''%parent%'')" key="{06b642f1-290d-4e36-8f40-9b52393288f7}" symbol="0" label="Executed Obsolete"/>
      <rule filter=" &quot;action&quot;= ''Execute psector'' AND &quot;psector_state&quot;=1 and &quot;doable&quot; is true" key="{128d6679-af73-43f1-99fb-e502b3e9732e}" symbol="1" label="Executed Planified"/>
      <rule filter=" &quot;action&quot;= ''Execute psector'' AND &quot;psector_state&quot;=1 and &quot;doable&quot; is false" key="{8fef7df2-517a-4909-bc97-0083c9603d04}" symbol="2" label="Executed Affected"/>
      <rule filter=" &quot;action&quot;= ''Cancel psector'' AND &quot;psector_state&quot;=0 AND (&quot;addparam&quot; IS NULL OR &quot;addparam&quot; NOT LIKE ''%parent%'')" key="{d3ab4235-c36e-45b1-a06e-5a19c70fc6bd}" symbol="3" label="Canceled Obsolete"/>
      <rule filter=" &quot;action&quot;= ''Cancel psector'' AND &quot;psector_state&quot;=1 and &quot;doable&quot; is true" key="{3d47ac0f-c0e2-42ad-a140-e3bbe5eb86f0}" symbol="4" label="Canceled Planified"/>
      <rule filter=" &quot;action&quot;= ''Cancel psector'' AND &quot;psector_state&quot;=1 and &quot;doable&quot; is false" key="{7e7209f5-05d8-4ce2-9cc7-aa2958ce48d6}" symbol="5" label="Canceled Affected"/>
    </rules>
    <symbols>
      <symbol type="line" name="0" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleLine" locked="0">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="227,26,28,255"/>
            <Option type="QString" name="line_style" value="dash"/>
            <Option type="QString" name="line_width" value="0.5"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" name="1" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleLine" locked="0">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="253,141,60,255"/>
            <Option type="QString" name="line_style" value="solid"/>
            <Option type="QString" name="line_width" value="0.5"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" name="2" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleLine" locked="0">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="107,174,214,255"/>
            <Option type="QString" name="line_style" value="solid"/>
            <Option type="QString" name="line_width" value="0.5"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" name="3" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleLine" locked="0">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="92,92,92,255"/>
            <Option type="QString" name="line_style" value="dash"/>
            <Option type="QString" name="line_width" value="0.5"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" name="4" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleLine" locked="0">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="0,0,0,255"/>
            <Option type="QString" name="line_style" value="solid"/>
            <Option type="QString" name="line_width" value="0.5"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="line" name="5" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleLine" locked="0">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="92,92,92,255"/>
            <Option type="QString" name="line_style" value="solid"/>
            <Option type="QString" name="line_width" value="0.5"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>1</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'audit_psector_connec_traceability', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.28.4-Firenze" styleCategories="Symbology">
  <renderer-v2 symbollevels="0" referencescale="-1" type="RuleRenderer" enableorderby="0" forceraster="0">
    <rules key="{dd77574c-a40f-48f5-98b9-0f51b503b645}">
      <rule filter=" &quot;action&quot;  =  ''Execute psector'' and &quot;psector_state&quot; = 1 and &quot;doable&quot; is false" key="{a07456bc-99df-42e0-a919-a3b2a1c56f45}" symbol="0" label="Executed Affected"/>
      <rule filter=" &quot;action&quot;  =  ''Execute psector'' and &quot;psector_state&quot; = 1 and &quot;doable&quot; is true" key="{a4dc1014-0b26-44cf-95a9-bbd8e2ac4094}" symbol="1" label="Executed Planified"/>
      <rule filter=" &quot;action&quot;  =  ''Execute psector'' and &quot;psector_state&quot; = 0" key="{10ce3b2c-8c7d-410f-941c-8aac2a4d3ccf}" symbol="2" label="Executed Obsolete"/>
      <rule filter=" &quot;action&quot;  =  ''Cancel psector'' and &quot;psector_state&quot; = 1 and &quot;doable&quot; is false" key="{612193eb-25aa-4bab-8183-d383fc640339}" symbol="3" label="Canceled Affected"/>
      <rule filter=" &quot;action&quot;  =  ''Cancel psector'' and &quot;psector_state&quot; = 1 and &quot;doable&quot; is true" key="{584b5e13-acb9-4c19-8420-04267f01a325}" symbol="4" label="Canceled Planified"/>
      <rule filter=" &quot;action&quot;  =  ''Cancel psector'' and &quot;psector_state&quot; = 0" key="{06216216-6694-4d66-ad65-a2cd74f3b0da}" symbol="5" label="Canceled Obsolete"/>
    </rules>
    <symbols>
      <symbol type="marker" name="0" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="49,180,227,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="49,180,227,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="QString" name="expression" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 3.5, 2, 0.37), 0))"/>
                  <Option type="int" name="type" value="3"/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="255,0,0,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="cross"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="0,0,0,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="3"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="QString" name="expression" value="var(''map_scale'')"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" name="exponent" value="0.37"/>
                      <Option type="double" name="maxSize" value="2"/>
                      <Option type="double" name="maxValue" value="1500"/>
                      <Option type="double" name="minSize" value="3.5"/>
                      <Option type="double" name="minValue" value="0"/>
                      <Option type="double" name="nullSize" value="0"/>
                      <Option type="int" name="scaleType" value="3"/>
                    </Option>
                    <Option type="int" name="t" value="1"/>
                  </Option>
                  <Option type="int" name="type" value="3"/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="marker" name="1" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="253,141,60,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="253,190,133,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="255,0,0,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="cross"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="0,0,0,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="3"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="QString" name="expression" value="var(''map_scale'')"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" name="exponent" value="0.37"/>
                      <Option type="double" name="maxSize" value="2"/>
                      <Option type="double" name="maxValue" value="1500"/>
                      <Option type="double" name="minSize" value="3.5"/>
                      <Option type="double" name="minValue" value="0"/>
                      <Option type="double" name="nullSize" value="0"/>
                      <Option type="int" name="scaleType" value="3"/>
                    </Option>
                    <Option type="int" name="t" value="1"/>
                  </Option>
                  <Option type="int" name="type" value="3"/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="marker" name="2" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="203,24,29,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="227,26,28,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="255,0,0,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="cross"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="0,0,0,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="3"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="QString" name="expression" value="var(''map_scale'')"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" name="exponent" value="0.37"/>
                      <Option type="double" name="maxSize" value="2"/>
                      <Option type="double" name="maxValue" value="1500"/>
                      <Option type="double" name="minSize" value="3.5"/>
                      <Option type="double" name="minValue" value="0"/>
                      <Option type="double" name="nullSize" value="0"/>
                      <Option type="int" name="scaleType" value="3"/>
                    </Option>
                    <Option type="int" name="t" value="1"/>
                  </Option>
                  <Option type="int" name="type" value="3"/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="marker" name="3" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="160,211,240,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="166,206,227,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="255,0,0,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="cross"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="0,0,0,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="3"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="QString" name="expression" value="var(''map_scale'')"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" name="exponent" value="0.37"/>
                      <Option type="double" name="maxSize" value="2"/>
                      <Option type="double" name="maxValue" value="1500"/>
                      <Option type="double" name="minSize" value="3.5"/>
                      <Option type="double" name="minValue" value="0"/>
                      <Option type="double" name="nullSize" value="0"/>
                      <Option type="int" name="scaleType" value="3"/>
                    </Option>
                    <Option type="int" name="t" value="1"/>
                  </Option>
                  <Option type="int" name="type" value="3"/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="marker" name="4" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="92,92,92,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="92,92,92,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="255,0,0,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="cross"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="0,0,0,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="3"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="QString" name="expression" value="var(''map_scale'')"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" name="exponent" value="0.37"/>
                      <Option type="double" name="maxSize" value="2"/>
                      <Option type="double" name="maxValue" value="1500"/>
                      <Option type="double" name="minSize" value="3.5"/>
                      <Option type="double" name="minValue" value="0"/>
                      <Option type="double" name="nullSize" value="0"/>
                      <Option type="int" name="scaleType" value="3"/>
                    </Option>
                    <Option type="int" name="t" value="1"/>
                  </Option>
                  <Option type="int" name="type" value="3"/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="marker" name="5" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="239,243,255,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="92,92,92,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="255,0,0,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="cross"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="0,0,0,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="3"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option type="Map" name="properties">
                <Option type="Map" name="angle">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="int" name="type" value="1"/>
                  <Option type="QString" name="val" value=""/>
                </Option>
                <Option type="Map" name="size">
                  <Option type="bool" name="active" value="false"/>
                  <Option type="QString" name="expression" value="var(''map_scale'')"/>
                  <Option type="Map" name="transformer">
                    <Option type="Map" name="d">
                      <Option type="double" name="exponent" value="0.37"/>
                      <Option type="double" name="maxSize" value="2"/>
                      <Option type="double" name="maxValue" value="1500"/>
                      <Option type="double" name="minSize" value="3.5"/>
                      <Option type="double" name="minValue" value="0"/>
                      <Option type="double" name="nullSize" value="0"/>
                      <Option type="int" name="scaleType" value="3"/>
                    </Option>
                    <Option type="int" name="t" value="1"/>
                  </Option>
                  <Option type="int" name="type" value="3"/>
                </Option>
              </Option>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'audit_psector_gully_traceability', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.28.4-Firenze">
  <renderer-v2 forceraster="0" type="RuleRenderer" enableorderby="0" referencescale="-1" symbollevels="0">
    <rules key="{dd77574c-a40f-48f5-98b9-0f51b503b645}">
      <rule label="Executed Affected" symbol="0" filter=" &quot;action&quot;  =  ''Execute psector'' and &quot;psector_state&quot; = 1 and &quot;doable&quot; is false" key="{a07456bc-99df-42e0-a919-a3b2a1c56f45}"/>
      <rule label="Executed Planified" symbol="1" filter=" &quot;action&quot;  =  ''Execute psector'' and &quot;psector_state&quot; = 1 and &quot;doable&quot; is true" key="{a4dc1014-0b26-44cf-95a9-bbd8e2ac4094}"/>
      <rule label="Executed Obsolete" symbol="2" filter=" &quot;action&quot;  =  ''Execute psector'' and &quot;psector_state&quot; = 0" key="{10ce3b2c-8c7d-410f-941c-8aac2a4d3ccf}"/>
      <rule label="Canceled Affected" symbol="3" filter=" &quot;action&quot;  =  ''Cancel psector'' and &quot;psector_state&quot; = 1 and &quot;doable&quot; is false" key="{612193eb-25aa-4bab-8183-d383fc640339}"/>
      <rule label="Canceled Planified" symbol="4" filter=" &quot;action&quot;  =  ''Cancel psector'' and &quot;psector_state&quot; = 1 and &quot;doable&quot; is true" key="{584b5e13-acb9-4c19-8420-04267f01a325}"/>
      <rule label="Canceled Obsolete" symbol="5" filter=" &quot;action&quot;  =  ''Cancel psector'' and &quot;psector_state&quot; = 0" key="{06216216-6694-4d66-ad65-a2cd74f3b0da}"/>
    </rules>
    <symbols>
      <symbol name="0" type="marker" force_rhr="0" alpha="1" frame_rate="10" clip_to_extent="1" is_animated="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" locked="0" class="SimpleMarker">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="49,180,227,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="49,180,227,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 3.5, 2, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="1" type="marker" force_rhr="0" alpha="1" frame_rate="10" clip_to_extent="1" is_animated="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" locked="0" class="SimpleMarker">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="253,141,60,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="255,127,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="2" type="marker" force_rhr="0" alpha="1" frame_rate="10" clip_to_extent="1" is_animated="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" locked="0" class="SimpleMarker">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="203,24,29,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="227,26,28,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="3" type="marker" force_rhr="0" alpha="1" frame_rate="10" clip_to_extent="1" is_animated="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" locked="0" class="SimpleMarker">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="160,211,240,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="166,206,227,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="4" type="marker" force_rhr="0" alpha="1" frame_rate="10" clip_to_extent="1" is_animated="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" locked="0" class="SimpleMarker">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="92,92,92,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="92,92,92,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="5" type="marker" force_rhr="0" alpha="1" frame_rate="10" clip_to_extent="1" is_animated="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" locked="0" class="SimpleMarker">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="239,243,255,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="167,167,167,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.4"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="false"/>
                  <Option name="type" type="int" value="1"/>
                  <Option name="val" type="QString" value=""/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'audit_psector_node_traceability', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.28.4-Firenze" styleCategories="Symbology">
  <renderer-v2 symbollevels="0" referencescale="-1" type="RuleRenderer" enableorderby="0" forceraster="0">
    <rules key="{0bdcbc18-d32d-45e0-b253-4a3ef128c84f}">
      <rule filter=" &quot;action&quot;  =  ''Execute psector'' and &quot;psector_state&quot;  = 1 and  &quot;doable&quot; is  true" key="{0331f768-d4a7-42a3-935e-0a8948ea49ee}" symbol="0" label="Executed Planified"/>
      <rule filter=" &quot;action&quot;  =  ''Execute psector'' and &quot;psector_state&quot;  = 0" key="{7a509b40-a9db-49c7-9bca-b90d07fb0933}" symbol="1" label="Executed Obsolete"/>
      <rule filter=" &quot;action&quot;  =  ''Cancel psector'' and &quot;psector_state&quot;  = 1 and  &quot;doable&quot; is  true" key="{1586d2ed-56d7-400e-81f5-2e003023d559}" symbol="2" label="Canceld Planified"/>
      <rule filter=" &quot;action&quot;  =  ''Cancel psector'' and &quot;psector_state&quot;  = 0" key="{d0f18ec3-fea9-40c7-91aa-19c8a1a875cd}" symbol="3" label="Canceled Obsolete"/>
    </rules>
    <symbols>
      <symbol type="marker" name="0" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="253,190,133,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="253,141,60,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0.4"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="marker" name="1" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="219,30,42,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="128,17,25,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0.4"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="marker" name="2" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="92,92,92,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="0,0,0,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0.4"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol type="marker" name="3" clip_to_extent="1" force_rhr="0" is_animated="0" frame_rate="10" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" name="angle" value="0"/>
            <Option type="QString" name="cap_style" value="square"/>
            <Option type="QString" name="color" value="245,245,245,255"/>
            <Option type="QString" name="horizontal_anchor_point" value="1"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="name" value="circle"/>
            <Option type="QString" name="offset" value="0,0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="outline_color" value="92,92,92,255"/>
            <Option type="QString" name="outline_style" value="solid"/>
            <Option type="QString" name="outline_width" value="0.4"/>
            <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="outline_width_unit" value="MM"/>
            <Option type="QString" name="scale_method" value="diameter"/>
            <Option type="QString" name="size" value="2"/>
            <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="size_unit" value="MM"/>
            <Option type="QString" name="vertical_anchor_point" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>
')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'v_plan_psector_arc', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.22.3-Białowieża" styleCategories="Symbology|Labeling" labelsEnabled="0">
  <renderer-v2 type="RuleRenderer" referencescale="-1" enableorderby="0" symbollevels="0" forceraster="0">
    <rules key="{865da60f-63a5-48c0-bd36-575459cd31ac}">
      <rule filter=" &quot;original_state&quot;  =  1 AND &quot;plan_state&quot;=0 AND (&quot;addparam&quot; LIKE ''%parent%'' OR &quot;addparam&quot; IS NULL)" symbol="0" key="{48d9c0ea-e321-4e09-bb68-c680931e12ba}" label="Planned obsolete network"/>
    </rules>
    <symbols>
      <symbol name="0" type="line" clip_to_extent="1" force_rhr="0" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option value="0" name="align_dash_pattern" type="QString"/>
            <Option value="square" name="capstyle" type="QString"/>
            <Option value="5;2" name="customdash" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
            <Option value="MM" name="customdash_unit" type="QString"/>
            <Option value="0" name="dash_pattern_offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
            <Option value="0" name="draw_inside_polygon" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="227,26,28,255" name="line_color" type="QString"/>
            <Option value="dash" name="line_style" type="QString"/>
            <Option value="0.5" name="line_width" type="QString"/>
            <Option value="MM" name="line_width_unit" type="QString"/>
            <Option value="0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="0" name="ring_filter" type="QString"/>
            <Option value="0" name="trim_distance_end" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
            <Option value="MM" name="trim_distance_end_unit" type="QString"/>
            <Option value="0" name="trim_distance_start" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
            <Option value="MM" name="trim_distance_start_unit" type="QString"/>
            <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
            <Option value="0" name="use_custom_dash" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
          </Option>
          <prop k="align_dash_pattern" v="0"/>
          <prop k="capstyle" v="square"/>
          <prop k="customdash" v="5;2"/>
          <prop k="customdash_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="customdash_unit" v="MM"/>
          <prop k="dash_pattern_offset" v="0"/>
          <prop k="dash_pattern_offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="dash_pattern_offset_unit" v="MM"/>
          <prop k="draw_inside_polygon" v="0"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="line_color" v="227,26,28,255"/>
          <prop k="line_style" v="dash"/>
          <prop k="line_width" v="0.5"/>
          <prop k="line_width_unit" v="MM"/>
          <prop k="offset" v="0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="ring_filter" v="0"/>
          <prop k="trim_distance_end" v="0"/>
          <prop k="trim_distance_end_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="trim_distance_end_unit" v="MM"/>
          <prop k="trim_distance_start" v="0"/>
          <prop k="trim_distance_start_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="trim_distance_start_unit" v="MM"/>
          <prop k="tweak_dash_pattern_on_corners" v="0"/>
          <prop k="use_custom_dash" v="0"/>
          <prop k="width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>1</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'v_plan_psector_connec', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis hasScaleBasedVisibilityFlag="0" simplifyDrawingTol="1" simplifyDrawingHints="0" simplifyLocal="1" maxScale="0" symbologyReferenceScale="-1" minScale="100000000" simplifyAlgorithm="0" simplifyMaxScale="1" styleCategories="Symbology|Rendering" version="3.22.4-Białowieża">
  <renderer-v2 forceraster="0" referencescale="-1" symbollevels="0" type="RuleRenderer" enableorderby="0">
    <rules key="{cd75f41e-3b1d-443c-8148-fbc4436aa9cb}">
      <rule filter="&quot;original_state&quot;  =  1 AND &quot;plan_state&quot;=0" symbol="0" scalemaxdenom="1500" label="Planned obsolete gully" key="{abcdb374-fe6a-4d04-a466-31fdd93144e8}" scalemindenom="1"/>
    </rules>
    <symbols>
      <symbol name="0" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="158,158,158,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="158,158,158,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="158,158,158,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="158,158,158,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="cross"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="255,0,0,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="cross"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerOpacity>1</layerOpacity>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'v_plan_psector_gully', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis hasScaleBasedVisibilityFlag="0" simplifyDrawingTol="1" simplifyDrawingHints="0" simplifyLocal="1" maxScale="0" symbologyReferenceScale="-1" minScale="100000000" simplifyAlgorithm="0" simplifyMaxScale="1" styleCategories="Symbology|Rendering" version="3.22.4-Białowieża">
  <renderer-v2 forceraster="0" referencescale="-1" symbollevels="0" type="RuleRenderer" enableorderby="0">
    <rules key="{cd75f41e-3b1d-443c-8148-fbc4436aa9cb}">
      <rule filter="&quot;original_state&quot;  =  1 AND &quot;plan_state&quot;=0" symbol="0" scalemaxdenom="1500" label="Planned obsolete gully" key="{abcdb374-fe6a-4d04-a466-31fdd93144e8}" scalemindenom="1"/>
    </rules>
    <symbols>
      <symbol name="0" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="158,158,158,103"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="158,158,158,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.6"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="158,158,158,103"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="158,158,158,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="1.6"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerOpacity>1</layerOpacity>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'v_plan_psector_link', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.22.3-Białowieża" styleCategories="Symbology|Labeling" labelsEnabled="0">
  <renderer-v2 type="RuleRenderer" referencescale="-1" enableorderby="0" symbollevels="0" forceraster="0">
    <rules key="{486daa37-8453-441a-855b-a910863aeec7}">
      <rule filter="&quot;original_state&quot;=1" symbol="0" scalemaxdenom="1500" key="{182a03af-5efd-4e18-930c-0f00e05f63f0}" label="Planned obsolete link"/>
    </rules>
    <symbols>
      <symbol name="0" type="line" clip_to_extent="1" force_rhr="0" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleLine" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option value="0" name="align_dash_pattern" type="QString"/>
            <Option value="square" name="capstyle" type="QString"/>
            <Option value="5;2" name="customdash" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
            <Option value="MM" name="customdash_unit" type="QString"/>
            <Option value="0" name="dash_pattern_offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
            <Option value="0" name="draw_inside_polygon" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="158,158,158,255" name="line_color" type="QString"/>
            <Option value="dot" name="line_style" type="QString"/>
            <Option value="0.26" name="line_width" type="QString"/>
            <Option value="MM" name="line_width_unit" type="QString"/>
            <Option value="0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="0" name="ring_filter" type="QString"/>
            <Option value="0" name="trim_distance_end" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
            <Option value="MM" name="trim_distance_end_unit" type="QString"/>
            <Option value="0" name="trim_distance_start" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
            <Option value="MM" name="trim_distance_start_unit" type="QString"/>
            <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
            <Option value="0" name="use_custom_dash" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
          </Option>
          <prop k="align_dash_pattern" v="0"/>
          <prop k="capstyle" v="square"/>
          <prop k="customdash" v="5;2"/>
          <prop k="customdash_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="customdash_unit" v="MM"/>
          <prop k="dash_pattern_offset" v="0"/>
          <prop k="dash_pattern_offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="dash_pattern_offset_unit" v="MM"/>
          <prop k="draw_inside_polygon" v="0"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="line_color" v="158,158,158,255"/>
          <prop k="line_style" v="dot"/>
          <prop k="line_width" v="0.26"/>
          <prop k="line_width_unit" v="MM"/>
          <prop k="offset" v="0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="ring_filter" v="0"/>
          <prop k="trim_distance_end" v="0"/>
          <prop k="trim_distance_end_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="trim_distance_end_unit" v="MM"/>
          <prop k="trim_distance_start" v="0"/>
          <prop k="trim_distance_start_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="trim_distance_start_unit" v="MM"/>
          <prop k="tweak_dash_pattern_on_corners" v="0"/>
          <prop k="use_custom_dash" v="0"/>
          <prop k="width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="GeometryGenerator" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option value="Marker" name="SymbolType" type="QString"/>
            <Option value="end_point ($geometry)" name="geometryModifier" type="QString"/>
            <Option value="MapUnit" name="units" type="QString"/>
          </Option>
          <prop k="SymbolType" v="Marker"/>
          <prop k="geometryModifier" v="end_point ($geometry)"/>
          <prop k="units" v="MapUnit"/>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
          <symbol name="@0@1" type="marker" clip_to_extent="1" force_rhr="0" alpha="1">
            <data_defined_properties>
              <Option type="Map">
                <Option value="" name="name" type="QString"/>
                <Option name="properties"/>
                <Option value="collection" name="type" type="QString"/>
              </Option>
            </data_defined_properties>
            <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
              <Option type="Map">
                <Option value="0" name="angle" type="QString"/>
                <Option value="square" name="cap_style" type="QString"/>
                <Option value="255,0,0,255" name="color" type="QString"/>
                <Option value="1" name="horizontal_anchor_point" type="QString"/>
                <Option value="bevel" name="joinstyle" type="QString"/>
                <Option value="cross2" name="name" type="QString"/>
                <Option value="0,0" name="offset" type="QString"/>
                <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
                <Option value="MM" name="offset_unit" type="QString"/>
                <Option value="35,35,35,255" name="outline_color" type="QString"/>
                <Option value="solid" name="outline_style" type="QString"/>
                <Option value="0" name="outline_width" type="QString"/>
                <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
                <Option value="MM" name="outline_width_unit" type="QString"/>
                <Option value="diameter" name="scale_method" type="QString"/>
                <Option value="1.8" name="size" type="QString"/>
                <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
                <Option value="MM" name="size_unit" type="QString"/>
                <Option value="1" name="vertical_anchor_point" type="QString"/>
              </Option>
              <prop k="angle" v="0"/>
              <prop k="cap_style" v="square"/>
              <prop k="color" v="255,0,0,255"/>
              <prop k="horizontal_anchor_point" v="1"/>
              <prop k="joinstyle" v="bevel"/>
              <prop k="name" v="cross2"/>
              <prop k="offset" v="0,0"/>
              <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
              <prop k="offset_unit" v="MM"/>
              <prop k="outline_color" v="35,35,35,255"/>
              <prop k="outline_style" v="solid"/>
              <prop k="outline_width" v="0"/>
              <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
              <prop k="outline_width_unit" v="MM"/>
              <prop k="scale_method" v="diameter"/>
              <prop k="size" v="1.8"/>
              <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
              <prop k="size_unit" v="MM"/>
              <prop k="vertical_anchor_point" v="1"/>
              <data_defined_properties>
                <Option type="Map">
                  <Option value="" name="name" type="QString"/>
                  <Option name="properties"/>
                  <Option value="collection" name="type" type="QString"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>1</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 'v_plan_psector_node', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.22.3-Białowieża" styleCategories="Symbology|Labeling" labelsEnabled="0">
  <renderer-v2 type="RuleRenderer" referencescale="-1" enableorderby="0" symbollevels="0" forceraster="0">
    <rules key="{f9bd1dda-e8cb-4456-b498-a3f1312029f9}">
      <rule filter="&quot;original_state&quot;  =  1 AND &quot;plan_state&quot;=0" symbol="0" scalemaxdenom="2500" key="{2bb6a916-46c5-4610-b8fa-4a7a93cfe697}" label="Planned obsolete node"/>
    </rules>
    <symbols>
      <symbol name="0" type="marker" clip_to_extent="1" force_rhr="0" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" enabled="1" locked="0" pass="0">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="158,158,158,255" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="50,48,55,255" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="1.8" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="158,158,158,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="50,48,55,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="1.8"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 've_node', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.40.7-Bratislava">
 <renderer-v2 symbollevels="0" referencescale="-1" forceraster="0" type="RuleRenderer" enableorderby="0">
  <rules key="{726173c1-e48a-4505-bde5-b50ffb7bba39}">
   <rule scalemaxdenom="25000" label="Storage" key="{d22d6bf4-55db-4cb5-8b49-25a3c52a3d1b}" filter="&quot;sys_type&quot; = ''STORAGE''" symbol="0"/>
   <rule scalemaxdenom="25000" label="Chamber" key="{2ad49ef6-10ef-413f-9dc9-82ff5a236362}" filter="&quot;sys_type&quot; = ''CHAMBER''" symbol="1"/>
   <rule scalemaxdenom="25000" label="Wwtp" key="{fbe58f73-553d-4064-8e10-43eed3ee776f}" filter="&quot;sys_type&quot; = ''WWTP''" symbol="2"/>
   <rule scalemaxdenom="10000" label="Netgully" key="{93522d7c-98e1-4e5f-a8ed-62fd17ca4f1f}" filter="&quot;sys_type&quot; = ''NETGULLY''" symbol="3"/>
   <rule scalemaxdenom="10000" label="Netelement" key="{e9f34e9b-5335-4553-aad1-8f52fb4b7fd9}" filter="&quot;sys_type&quot; = ''NETELEMENT''" symbol="4"/>
   <rule scalemaxdenom="10000" label="Manhole" key="{c4d73b40-d93d-4ba0-b066-ff35c7a380fa}" filter="&quot;sys_type&quot; = ''MANHOLE''" symbol="5"/>
   <rule scalemaxdenom="10000" label="Netinit" key="{ab7634fb-6056-43cb-b569-bed1e561bc34}" filter="&quot;sys_type&quot; = ''NETINIT''" symbol="6"/>
   <rule scalemaxdenom="10000" label="Wjump" key="{010803db-b772-4cda-b196-1767fa88163b}" filter="&quot;sys_type&quot; = ''WJUMP''" symbol="7"/>
   <rule scalemaxdenom="10000" label="Junction" key="{1aea5824-3d04-41eb-9016-bc26e1c51f00}" filter="&quot;sys_type&quot; = ''JUNCTION''" symbol="8"/>
   <rule scalemaxdenom="10000" label="Outfall" key="{be5b7b53-a9d4-4085-af09-11a3194dacd4}" filter="&quot;sys_type&quot; = ''OUTFALL''" symbol="9"/>
   <rule scalemaxdenom="10000" label="Valve" key="{75dd03f5-eb03-4155-8f29-0179198c1276}" filter="&quot;sys_type&quot; = ''VALVE''" symbol="10"/>
   <rule label="ELSE" key="{a1136c92-02fe-48ae-a5fb-ee4cc74ed59b}" filter="ELSE" symbol="11"/>
  </rules>
  <symbols>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{4139793a-18d0-4b5c-bc75-f41f3a7b5779}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="44,67,207,255,rgb:0.17254901960784313,0.2627450980392157,0.81176470588235294,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="square" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2.5" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.36999999999999994" type="double" name="exponent"/>
           <Option value="0.5" type="double" name="maxSize"/>
           <Option value="25000" type="double" name="maxValue"/>
           <Option value="4.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="1" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{1179b589-e711-4659-b3d7-67d5f3da78f2}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="31,120,180,255,rgb:0.12156862745098039,0.47058823529411764,0.70588235294117652,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="square" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2.5" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.36999999999999994" type="double" name="exponent"/>
           <Option value="0.5" type="double" name="maxSize"/>
           <Option value="25000" type="double" name="maxValue"/>
           <Option value="4.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="10" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{2d774c18-3b60-4c9e-9ecd-53008777ba97}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="255,255,255,255,rgb:1,1,1,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.36999999999999994" type="double" name="exponent"/>
           <Option value="0.3" type="double" name="maxSize"/>
           <Option value="10000" type="double" name="maxValue"/>
           <Option value="3.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="11" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{598777f4-654c-4e8c-9281-7cf254454945}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option name="properties"/>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="2" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{209eda1d-d4a0-438c-9173-3ef3ab79623a}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="50,48,55,255,rgb:0.19607843137254902,0.18823529411764706,0.21568627450980393,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="square" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="3" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.37" type="double" name="exponent"/>
           <Option value="0.5" type="double" name="maxSize"/>
           <Option value="25000" type="double" name="maxValue"/>
           <Option value="4.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="SimpleMarker" pass="0" id="{4702f03f-33d6-4014-970d-18db360c593b}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0))" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="3" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{235b2722-111d-46ee-a67e-273027c81abf}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="106,233,255,0,rgb:0.41568627450980394,0.9137254901960784,1,0" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="1.8" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.36999999999999994" type="double" name="exponent"/>
           <Option value="0.3" type="double" name="maxSize"/>
           <Option value="10000" type="double" name="maxValue"/>
           <Option value="3.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="4" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{44b56ed7-0be5-4cee-aee0-e9bb26e8ed60}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="129,10,78,255,rgb:0.50588235294117645,0.0392156862745098,0.30588235294117649,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.36999999999999994" type="double" name="exponent"/>
           <Option value="0.3" type="double" name="maxSize"/>
           <Option value="10000" type="double" name="maxValue"/>
           <Option value="3.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="5" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{d37e5a6f-35ff-4504-8e37-feea38bb15a2}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="106,233,255,255,rgb:0.41568627450980394,0.9137254901960784,1,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.37" type="double" name="exponent"/>
           <Option value="0.3" type="double" name="maxSize"/>
           <Option value="10000" type="double" name="maxValue"/>
           <Option value="3.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="6" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{14da8ea3-17a9-467a-b864-7165f04e9ddf}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="26,115,162,255,rgb:0.10196078431372549,0.45098039215686275,0.63529411764705879,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="3" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.36999999999999994" type="double" name="exponent"/>
           <Option value="0.3" type="double" name="maxSize"/>
           <Option value="10000" type="double" name="maxValue"/>
           <Option value="4" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="7" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{4bf54520-34f7-444b-ae0a-bf5c8d7c207c}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="147,218,255,255,rgb:0.57647058823529407,0.85490196078431369,1,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.36999999999999994" type="double" name="exponent"/>
           <Option value="0.3" type="double" name="maxSize"/>
           <Option value="10000" type="double" name="maxValue"/>
           <Option value="3.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="SimpleMarker" pass="0" id="{01761201-7176-4576-9d02-30625002275d}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="147,218,255,255,rgb:0.57647058823529407,0.85490196078431369,1,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="0.5" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="8" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{0a9a2686-2556-4dc6-827c-3e56cbb69f62}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="45,136,255,255,rgb:0.17647058823529413,0.53333333333333333,1,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.37" type="double" name="exponent"/>
           <Option value="0.3" type="double" name="maxSize"/>
           <Option value="10000" type="double" name="maxValue"/>
           <Option value="3.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer class="SimpleMarker" pass="0" id="{adcb4267-a7be-4bab-afa4-94532d0b03e2}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="255,0,0,0,rgb:1,0,0,0" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="0.5" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))" type="QString" name="expression"/>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="9" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{5edc1944-7988-4ed8-8960-7f2c9711180b}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="227,26,28,255,rgb:0.8901960784313725,0.10196078431372549,0.10980392156862745,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="filled_arrowhead" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="0,0,0,255,rgb:0,0,0,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="3.5" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option type="Map" name="properties">
        <Option type="Map" name="size">
         <Option value="true" type="bool" name="active"/>
         <Option value="var(''map_scale'')" type="QString" name="expression"/>
         <Option type="Map" name="transformer">
          <Option type="Map" name="d">
           <Option value="0.36999999999999994" type="double" name="exponent"/>
           <Option value="0.3" type="double" name="maxSize"/>
           <Option value="10000" type="double" name="maxValue"/>
           <Option value="3.5" type="double" name="minSize"/>
           <Option value="0" type="double" name="minValue"/>
           <Option value="0" type="double" name="nullSize"/>
           <Option value="3" type="int" name="scaleType"/>
          </Option>
          <Option value="1" type="int" name="t"/>
         </Option>
         <Option value="3" type="int" name="type"/>
        </Option>
       </Option>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </symbols>
  <data-defined-properties>
   <Option type="Map">
    <Option value="" type="QString" name="name"/>
    <Option name="properties"/>
    <Option value="collection" type="QString" name="type"/>
   </Option>
  </data-defined-properties>
 </renderer-v2>
 <selection mode="Default">
  <selectionColor invalid="1"/>
  <selectionSymbol>
   <symbol is_animated="0" force_rhr="0" type="marker" clip_to_extent="1" frame_rate="10" name="" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" type="QString" name="name"/>
      <Option name="properties"/>
      <Option value="collection" type="QString" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleMarker" pass="0" id="{4dde61b6-903a-4c6e-b4dc-07a344b202e2}" enabled="1" locked="0">
     <Option type="Map">
      <Option value="0" type="QString" name="angle"/>
      <Option value="square" type="QString" name="cap_style"/>
      <Option value="255,0,0,255,rgb:1,0,0,1" type="QString" name="color"/>
      <Option value="1" type="QString" name="horizontal_anchor_point"/>
      <Option value="bevel" type="QString" name="joinstyle"/>
      <Option value="circle" type="QString" name="name"/>
      <Option value="0,0" type="QString" name="offset"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
      <Option value="MM" type="QString" name="offset_unit"/>
      <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString" name="outline_color"/>
      <Option value="solid" type="QString" name="outline_style"/>
      <Option value="0" type="QString" name="outline_width"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
      <Option value="MM" type="QString" name="outline_width_unit"/>
      <Option value="diameter" type="QString" name="scale_method"/>
      <Option value="2" type="QString" name="size"/>
      <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
      <Option value="MM" type="QString" name="size_unit"/>
      <Option value="1" type="QString" name="vertical_anchor_point"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" type="QString" name="name"/>
       <Option name="properties"/>
       <Option value="collection" type="QString" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </selectionSymbol>
 </selection>
 <blendMode>0</blendMode>
 <featureBlendMode>0</featureBlendMode>
 <layerGeometryType>0</layerGeometryType>
</qgis>
')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('101', 've_pol_node', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis hasScaleBasedVisibilityFlag="1" simplifyDrawingTol="1" simplifyDrawingHints="1" simplifyLocal="1" maxScale="0" symbologyReferenceScale="-1" minScale="5000" simplifyAlgorithm="0" simplifyMaxScale="1" styleCategories="Symbology|Rendering" version="3.22.4-Białowieża">
  <renderer-v2 forceraster="0" referencescale="-1" symbollevels="0" type="RuleRenderer" enableorderby="0">
    <rules key="{1ddb4e79-3518-4379-8135-7c3e59f2170d}">
      <rule filter="&quot;featurecat_id&quot; = ''CHAMBER''" symbol="0" label="CHAMBER" key="{8fa1d9bb-54f5-4940-b894-f7e28ed9fbd4}"/>
      <rule filter="&quot;featurecat_id&quot; = ''NETGULLY''" symbol="1" label="NETGULLY" key="{d279634e-a716-400c-b25d-977d275f2678}"/>
      <rule filter="&quot;featurecat_id&quot; = ''STORAGE''" symbol="2" label="STORAGE" key="{3f9558a4-dd1c-4d7c-95ed-6e15cde5f129}"/>
      <rule filter="ELSE" symbol="3" label="OTHERS" key="{2c3f3682-0dc1-4070-bef0-df66ce3d98e1}"/>
    </rules>
    <symbols>
      <symbol name="0" alpha="0.6" clip_to_extent="1" type="fill" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="border_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="color" type="QString" value="73,149,255,255"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="30,62,105,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.26"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="style" type="QString" value="solid"/>
          </Option>
          <prop k="border_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="color" v="73,149,255,255"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="30,62,105,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0.26"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="style" v="solid"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="1" alpha="0.6" clip_to_extent="1" type="fill" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="border_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="color" type="QString" value="150,165,180,255"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="81,89,97,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.26"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="style" type="QString" value="solid"/>
          </Option>
          <prop k="border_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="color" v="150,165,180,255"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="81,89,97,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0.26"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="style" v="solid"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="2" alpha="0.6" clip_to_extent="1" type="fill" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="border_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="color" type="QString" value="123,135,147,255"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="77,77,77,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.26"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="style" type="QString" value="solid"/>
          </Option>
          <prop k="border_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="color" v="123,135,147,255"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="77,77,77,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0.26"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="style" v="solid"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="3" alpha="0.6" clip_to_extent="1" type="fill" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleFill" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="border_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="color" type="QString" value="255,73,73,255"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="130,37,37,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.26"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="style" type="QString" value="solid"/>
          </Option>
          <prop k="border_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="color" v="255,73,73,255"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="130,37,37,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0.26"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="style" v="solid"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerOpacity>1</layerOpacity>
  <layerGeometryType>2</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('102', 've_arc', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis simplifyMaxScale="1" hasScaleBasedVisibilityFlag="0" readOnly="0" maxScale="0" simplifyDrawingTol="1" simplifyAlgorithm="0" symbologyReferenceScale="-1" version="3.28.5-Firenze" styleCategories="AllStyleCategories" minScale="0" labelsEnabled="1" simplifyLocal="1" simplifyDrawingHints="1">
 <flags>
  <Identifiable>1</Identifiable>
  <Removable>1</Removable>
  <Searchable>1</Searchable>
  <Private>0</Private>
 </flags>
 <temporal limitMode="0" endField="" fixedDuration="0" mode="0" startExpression="" enabled="0" endExpression="" durationField="" accumulate="0" durationUnit="min" startField="">
  <fixedRange>
   <start></start>
   <end></end>
  </fixedRange>
 </temporal>
 <elevation binding="Centroid" showMarkerSymbolInSurfacePlots="0" zoffset="0" symbology="Line" extrusionEnabled="0" respectLayerSymbol="1" zscale="1" extrusion="0" clamping="Terrain" type="IndividualFeatures">
  <data-defined-properties>
   <Option type="Map">
    <Option value="" name="name" type="QString"/>
    <Option name="properties"/>
    <Option value="collection" name="type" type="QString"/>
   </Option>
  </data-defined-properties>
  <profileLineSymbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="" type="line" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleLine">
     <Option type="Map">
      <Option value="0" name="align_dash_pattern" type="QString"/>
      <Option value="square" name="capstyle" type="QString"/>
      <Option value="5;2" name="customdash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
      <Option value="MM" name="customdash_unit" type="QString"/>
      <Option value="0" name="dash_pattern_offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
      <Option value="0" name="draw_inside_polygon" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="145,82,45,255" name="line_color" type="QString"/>
      <Option value="solid" name="line_style" type="QString"/>
      <Option value="0.6" name="line_width" type="QString"/>
      <Option value="MM" name="line_width_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="0" name="trim_distance_end" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_end_unit" type="QString"/>
      <Option value="0" name="trim_distance_start" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_start_unit" type="QString"/>
      <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
      <Option value="0" name="use_custom_dash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties"/>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </profileLineSymbol>
  <profileFillSymbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="" type="fill" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleFill">
     <Option type="Map">
      <Option value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale" type="QString"/>
      <Option value="145,82,45,255" name="color" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="0,0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="104,59,32,255" name="outline_color" type="QString"/>
      <Option value="solid" name="outline_style" type="QString"/>
      <Option value="0.2" name="outline_width" type="QString"/>
      <Option value="MM" name="outline_width_unit" type="QString"/>
      <Option value="solid" name="style" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties"/>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </profileFillSymbol>
  <profileMarkerSymbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="" type="marker" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleMarker">
     <Option type="Map">
      <Option value="0" name="angle" type="QString"/>
      <Option value="square" name="cap_style" type="QString"/>
      <Option value="145,82,45,255" name="color" type="QString"/>
      <Option value="1" name="horizontal_anchor_point" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="diamond" name="name" type="QString"/>
      <Option value="0,0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="104,59,32,255" name="outline_color" type="QString"/>
      <Option value="solid" name="outline_style" type="QString"/>
      <Option value="0.2" name="outline_width" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
      <Option value="MM" name="outline_width_unit" type="QString"/>
      <Option value="diameter" name="scale_method" type="QString"/>
      <Option value="3" name="size" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
      <Option value="MM" name="size_unit" type="QString"/>
      <Option value="1" name="vertical_anchor_point" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties"/>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </profileMarkerSymbol>
 </elevation>
 <renderer-v2 forceraster="0" type="RuleRenderer" enableorderby="0" symbollevels="0" referencescale="-1">
  <rules key="{4cb3e952-bd79-40ee-9f19-dc8fa18f2452}">
   <rule symbol="0" label="CONDUIT" key="{294ddb79-aff2-4244-a83c-29b1c7e34366}" filter="&quot;inp_type&quot; = ''CONDUIT''"/>
   <rule symbol="1" label="VIRTUAL" key="{bd4ace4b-318d-428c-a3c1-0ce17445beda}" filter="&quot;inp_type&quot; = ''VIRTUAL''"/>
   <rule symbol="2" label="PUMP" key="{2f673a7d-f319-42d8-a666-36380c3a0818}" filter="&quot;inp_type&quot; = ''PUMP''"/>
   <rule symbol="3" label="WEIR" key="{dde3a32f-0f78-4ca9-b6c5-6ca0f43a7cec}" filter="&quot;inp_type&quot; = ''WEIR''"/>
   <rule symbol="4" label="ORIFICE" key="{3ca1f4ff-af9b-4c83-beb6-5e924bcac7ec}" filter="&quot;inp_type&quot; = ''ORIFICE''"/>
   <rule symbol="5" label="OUTLET" key="{4007a203-30ed-448e-8322-65999b1f7a07}" filter="&quot;inp_type&quot; = ''OUTLET''"/>
   <rule symbol="6" label="NOT USED" key="{9c3b163a-25f9-44cc-a324-c05147612097}" filter="&quot;inp_type&quot; IS NULL"/>
  </rules>
  <symbols>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="0" type="line" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleLine">
     <Option type="Map">
      <Option value="0" name="align_dash_pattern" type="QString"/>
      <Option value="square" name="capstyle" type="QString"/>
      <Option value="5;2" name="customdash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
      <Option value="MM" name="customdash_unit" type="QString"/>
      <Option value="0" name="dash_pattern_offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
      <Option value="0" name="draw_inside_polygon" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="31,120,180,255" name="line_color" type="QString"/>
      <Option value="solid" name="line_style" type="QString"/>
      <Option value="0.56" name="line_width" type="QString"/>
      <Option value="MM" name="line_width_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="0" name="trim_distance_end" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_end_unit" type="QString"/>
      <Option value="0" name="trim_distance_start" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_start_unit" type="QString"/>
      <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
      <Option value="0" name="use_custom_dash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 0.55&#xd;&#xa;WHEN @map_scale  > 5000 THEN  &quot;conduit_cat_geom1&quot; * 0.4&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer pass="0" locked="0" enabled="1" class="MarkerLine">
     <Option type="Map">
      <Option value="4" name="average_angle_length" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale" type="QString"/>
      <Option value="MM" name="average_angle_unit" type="QString"/>
      <Option value="3" name="interval" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="interval_map_unit_scale" type="QString"/>
      <Option value="MM" name="interval_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="0" name="offset_along_line" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_along_line_unit" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="true" name="place_on_every_part" type="bool"/>
      <Option value="CentralPoint" name="placements" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="1" name="rotate" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 5000 THEN 0&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
     <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="@0@1" type="marker" force_rhr="0" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
      </data_defined_properties>
      <layer pass="0" locked="0" enabled="1" class="SimpleMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="square" name="cap_style" type="QString"/>
        <Option value="31,120,180,255" name="color" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="filled_arrowhead" name="name" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="0,0,0,255" name="outline_color" type="QString"/>
        <Option value="solid" name="outline_style" type="QString"/>
        <Option value="0" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="diameter" name="scale_method" type="QString"/>
        <Option value="1.56" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties" type="Map">
          <Option name="size" type="Map">
           <Option value="true" name="active" type="bool"/>
           <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 1000 THEN 0&#xd;&#xa;END" name="expression" type="QString"/>
           <Option value="3" name="type" type="int"/>
          </Option>
         </Option>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="1" type="line" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleLine">
     <Option type="Map">
      <Option value="0" name="align_dash_pattern" type="QString"/>
      <Option value="square" name="capstyle" type="QString"/>
      <Option value="5;2" name="customdash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
      <Option value="MM" name="customdash_unit" type="QString"/>
      <Option value="0" name="dash_pattern_offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
      <Option value="0" name="draw_inside_polygon" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="31,120,180,255" name="line_color" type="QString"/>
      <Option value="dot" name="line_style" type="QString"/>
      <Option value="0.56" name="line_width" type="QString"/>
      <Option value="MM" name="line_width_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="0" name="trim_distance_end" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_end_unit" type="QString"/>
      <Option value="0" name="trim_distance_start" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_start_unit" type="QString"/>
      <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
      <Option value="0" name="use_custom_dash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 0.55&#xd;&#xa;WHEN @map_scale  > 5000 THEN  &quot;conduit_cat_geom1&quot; * 0.4&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer pass="0" locked="0" enabled="1" class="MarkerLine">
     <Option type="Map">
      <Option value="4" name="average_angle_length" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale" type="QString"/>
      <Option value="MM" name="average_angle_unit" type="QString"/>
      <Option value="3" name="interval" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="interval_map_unit_scale" type="QString"/>
      <Option value="MM" name="interval_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="0" name="offset_along_line" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_along_line_unit" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="true" name="place_on_every_part" type="bool"/>
      <Option value="CentralPoint" name="placements" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="1" name="rotate" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 5000 THEN 0&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
     <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="@1@1" type="marker" force_rhr="0" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
      </data_defined_properties>
      <layer pass="0" locked="0" enabled="1" class="SimpleMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="square" name="cap_style" type="QString"/>
        <Option value="31,120,180,255" name="color" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="filled_arrowhead" name="name" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="0,0,0,255" name="outline_color" type="QString"/>
        <Option value="solid" name="outline_style" type="QString"/>
        <Option value="0" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="diameter" name="scale_method" type="QString"/>
        <Option value="1.56" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties" type="Map">
          <Option name="size" type="Map">
           <Option value="true" name="active" type="bool"/>
           <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 1000 THEN 0&#xd;&#xa;END" name="expression" type="QString"/>
           <Option value="3" name="type" type="int"/>
          </Option>
         </Option>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="2" type="line" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleLine">
     <Option type="Map">
      <Option value="0" name="align_dash_pattern" type="QString"/>
      <Option value="square" name="capstyle" type="QString"/>
      <Option value="5;2" name="customdash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
      <Option value="MM" name="customdash_unit" type="QString"/>
      <Option value="0" name="dash_pattern_offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
      <Option value="0" name="draw_inside_polygon" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="31,120,180,255" name="line_color" type="QString"/>
      <Option value="solid" name="line_style" type="QString"/>
      <Option value="0.483636" name="line_width" type="QString"/>
      <Option value="MM" name="line_width_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="0" name="trim_distance_end" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_end_unit" type="QString"/>
      <Option value="0" name="trim_distance_start" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_start_unit" type="QString"/>
      <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
      <Option value="0" name="use_custom_dash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 0.55&#xd;&#xa;WHEN @map_scale  > 5000 THEN  &quot;conduit_cat_geom1&quot; * 0.4&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer pass="0" locked="0" enabled="1" class="MarkerLine">
     <Option type="Map">
      <Option value="4" name="average_angle_length" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale" type="QString"/>
      <Option value="MM" name="average_angle_unit" type="QString"/>
      <Option value="3" name="interval" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="interval_map_unit_scale" type="QString"/>
      <Option value="MM" name="interval_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="0" name="offset_along_line" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_along_line_unit" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="true" name="place_on_every_part" type="bool"/>
      <Option value="CentralPoint" name="placements" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="1" name="rotate" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 5000 THEN 0&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
     <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="@2@1" type="marker" force_rhr="0" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
      </data_defined_properties>
      <layer pass="0" locked="0" enabled="1" class="SimpleMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="square" name="cap_style" type="QString"/>
        <Option value="237,124,89,255" name="color" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="circle" name="name" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="50,87,128,255" name="outline_color" type="QString"/>
        <Option value="solid" name="outline_style" type="QString"/>
        <Option value="0.4" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="diameter" name="scale_method" type="QString"/>
        <Option value="3.8" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties"/>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
      <layer pass="0" locked="0" enabled="1" class="FontMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="P" name="chr" type="QString"/>
        <Option value="0,0,0,255" name="color" type="QString"/>
        <Option value="Arial" name="font" type="QString"/>
        <Option value="" name="font_style" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="35,35,35,255" name="outline_color" type="QString"/>
        <Option value="0" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="1.9" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties"/>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="3" type="line" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleLine">
     <Option type="Map">
      <Option value="0" name="align_dash_pattern" type="QString"/>
      <Option value="square" name="capstyle" type="QString"/>
      <Option value="5;2" name="customdash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
      <Option value="MM" name="customdash_unit" type="QString"/>
      <Option value="0" name="dash_pattern_offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
      <Option value="0" name="draw_inside_polygon" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="31,120,180,255" name="line_color" type="QString"/>
      <Option value="solid" name="line_style" type="QString"/>
      <Option value="0.483636" name="line_width" type="QString"/>
      <Option value="MM" name="line_width_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="0" name="trim_distance_end" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_end_unit" type="QString"/>
      <Option value="0" name="trim_distance_start" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_start_unit" type="QString"/>
      <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
      <Option value="0" name="use_custom_dash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 0.55&#xd;&#xa;WHEN @map_scale  > 5000 THEN  &quot;conduit_cat_geom1&quot; * 0.4&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer pass="0" locked="0" enabled="1" class="MarkerLine">
     <Option type="Map">
      <Option value="4" name="average_angle_length" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale" type="QString"/>
      <Option value="MM" name="average_angle_unit" type="QString"/>
      <Option value="3" name="interval" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="interval_map_unit_scale" type="QString"/>
      <Option value="MM" name="interval_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="0" name="offset_along_line" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_along_line_unit" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="true" name="place_on_every_part" type="bool"/>
      <Option value="CentralPoint" name="placements" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="1" name="rotate" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 5000 THEN 0&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
     <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="@3@1" type="marker" force_rhr="0" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
      </data_defined_properties>
      <layer pass="0" locked="0" enabled="1" class="SimpleMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="square" name="cap_style" type="QString"/>
        <Option value="234,237,205,255" name="color" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="circle" name="name" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="50,87,128,255" name="outline_color" type="QString"/>
        <Option value="solid" name="outline_style" type="QString"/>
        <Option value="0.4" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="diameter" name="scale_method" type="QString"/>
        <Option value="3.8" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties"/>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
      <layer pass="0" locked="0" enabled="1" class="FontMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="W" name="chr" type="QString"/>
        <Option value="0,0,0,255" name="color" type="QString"/>
        <Option value="Arial" name="font" type="QString"/>
        <Option value="" name="font_style" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="35,35,35,255" name="outline_color" type="QString"/>
        <Option value="0" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="1.9" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties"/>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="4" type="line" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleLine">
     <Option type="Map">
      <Option value="0" name="align_dash_pattern" type="QString"/>
      <Option value="square" name="capstyle" type="QString"/>
      <Option value="5;2" name="customdash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
      <Option value="MM" name="customdash_unit" type="QString"/>
      <Option value="0" name="dash_pattern_offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
      <Option value="0" name="draw_inside_polygon" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="31,120,180,255" name="line_color" type="QString"/>
      <Option value="solid" name="line_style" type="QString"/>
      <Option value="0.483636" name="line_width" type="QString"/>
      <Option value="MM" name="line_width_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="0" name="trim_distance_end" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_end_unit" type="QString"/>
      <Option value="0" name="trim_distance_start" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_start_unit" type="QString"/>
      <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
      <Option value="0" name="use_custom_dash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 0.55&#xd;&#xa;WHEN @map_scale  > 5000 THEN  &quot;conduit_cat_geom1&quot; * 0.4&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer pass="0" locked="0" enabled="1" class="MarkerLine">
     <Option type="Map">
      <Option value="4" name="average_angle_length" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale" type="QString"/>
      <Option value="MM" name="average_angle_unit" type="QString"/>
      <Option value="3" name="interval" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="interval_map_unit_scale" type="QString"/>
      <Option value="MM" name="interval_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="0" name="offset_along_line" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_along_line_unit" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="true" name="place_on_every_part" type="bool"/>
      <Option value="CentralPoint" name="placements" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="1" name="rotate" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 5000 THEN 0&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
     <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="@4@1" type="marker" force_rhr="0" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
      </data_defined_properties>
      <layer pass="0" locked="0" enabled="1" class="SimpleMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="square" name="cap_style" type="QString"/>
        <Option value="197,203,117,255" name="color" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="circle" name="name" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="50,87,128,255" name="outline_color" type="QString"/>
        <Option value="solid" name="outline_style" type="QString"/>
        <Option value="0.4" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="diameter" name="scale_method" type="QString"/>
        <Option value="3.8" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties"/>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
      <layer pass="0" locked="0" enabled="1" class="FontMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="O" name="chr" type="QString"/>
        <Option value="0,0,0,255" name="color" type="QString"/>
        <Option value="Arial" name="font" type="QString"/>
        <Option value="" name="font_style" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="35,35,35,255" name="outline_color" type="QString"/>
        <Option value="0" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="1.9" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties"/>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="5" type="line" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleLine">
     <Option type="Map">
      <Option value="0" name="align_dash_pattern" type="QString"/>
      <Option value="square" name="capstyle" type="QString"/>
      <Option value="5;2" name="customdash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
      <Option value="MM" name="customdash_unit" type="QString"/>
      <Option value="0" name="dash_pattern_offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
      <Option value="0" name="draw_inside_polygon" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="31,120,180,255" name="line_color" type="QString"/>
      <Option value="solid" name="line_style" type="QString"/>
      <Option value="0.483636" name="line_width" type="QString"/>
      <Option value="MM" name="line_width_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="0" name="trim_distance_end" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_end_unit" type="QString"/>
      <Option value="0" name="trim_distance_start" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_start_unit" type="QString"/>
      <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
      <Option value="0" name="use_custom_dash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 0.55&#xd;&#xa;WHEN @map_scale  > 5000 THEN  &quot;conduit_cat_geom1&quot; * 0.4&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
    <layer pass="0" locked="0" enabled="1" class="MarkerLine">
     <Option type="Map">
      <Option value="4" name="average_angle_length" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="average_angle_map_unit_scale" type="QString"/>
      <Option value="MM" name="average_angle_unit" type="QString"/>
      <Option value="3" name="interval" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="interval_map_unit_scale" type="QString"/>
      <Option value="MM" name="interval_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="0" name="offset_along_line" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_along_line_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_along_line_unit" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="true" name="place_on_every_part" type="bool"/>
      <Option value="CentralPoint" name="placements" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="1" name="rotate" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties" type="Map">
        <Option name="outlineWidth" type="Map">
         <Option value="true" name="active" type="bool"/>
         <Option value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 5000 THEN 2.0 &#xd;&#xa;WHEN @map_scale  > 5000 THEN 0&#xd;&#xa;END" name="expression" type="QString"/>
         <Option value="3" name="type" type="int"/>
        </Option>
       </Option>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
     <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="@5@1" type="marker" force_rhr="0" alpha="1">
      <data_defined_properties>
       <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
      </data_defined_properties>
      <layer pass="0" locked="0" enabled="1" class="SimpleMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="square" name="cap_style" type="QString"/>
        <Option value="175,186,23,255" name="color" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="circle" name="name" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="50,87,128,255" name="outline_color" type="QString"/>
        <Option value="solid" name="outline_style" type="QString"/>
        <Option value="0.4" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="diameter" name="scale_method" type="QString"/>
        <Option value="3.8" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties"/>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
      <layer pass="0" locked="0" enabled="1" class="FontMarker">
       <Option type="Map">
        <Option value="0" name="angle" type="QString"/>
        <Option value="L" name="chr" type="QString"/>
        <Option value="0,0,0,255" name="color" type="QString"/>
        <Option value="Arial" name="font" type="QString"/>
        <Option value="" name="font_style" type="QString"/>
        <Option value="1" name="horizontal_anchor_point" type="QString"/>
        <Option value="bevel" name="joinstyle" type="QString"/>
        <Option value="0,0" name="offset" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
        <Option value="MM" name="offset_unit" type="QString"/>
        <Option value="35,35,35,255" name="outline_color" type="QString"/>
        <Option value="0" name="outline_width" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
        <Option value="MM" name="outline_width_unit" type="QString"/>
        <Option value="1.9" name="size" type="QString"/>
        <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
        <Option value="MM" name="size_unit" type="QString"/>
        <Option value="1" name="vertical_anchor_point" type="QString"/>
       </Option>
       <data_defined_properties>
        <Option type="Map">
         <Option value="" name="name" type="QString"/>
         <Option name="properties"/>
         <Option value="collection" name="type" type="QString"/>
        </Option>
       </data_defined_properties>
      </layer>
     </symbol>
    </layer>
   </symbol>
   <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="6" type="line" force_rhr="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option value="" name="name" type="QString"/>
      <Option name="properties"/>
      <Option value="collection" name="type" type="QString"/>
     </Option>
    </data_defined_properties>
    <layer pass="0" locked="0" enabled="1" class="SimpleLine">
     <Option type="Map">
      <Option value="0" name="align_dash_pattern" type="QString"/>
      <Option value="square" name="capstyle" type="QString"/>
      <Option value="5;2" name="customdash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
      <Option value="MM" name="customdash_unit" type="QString"/>
      <Option value="0" name="dash_pattern_offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
      <Option value="0" name="draw_inside_polygon" type="QString"/>
      <Option value="bevel" name="joinstyle" type="QString"/>
      <Option value="206,206,206,255" name="line_color" type="QString"/>
      <Option value="solid" name="line_style" type="QString"/>
      <Option value="0.5" name="line_width" type="QString"/>
      <Option value="MM" name="line_width_unit" type="QString"/>
      <Option value="0" name="offset" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
      <Option value="MM" name="offset_unit" type="QString"/>
      <Option value="0" name="ring_filter" type="QString"/>
      <Option value="0" name="trim_distance_end" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_end_unit" type="QString"/>
      <Option value="0" name="trim_distance_start" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
      <Option value="MM" name="trim_distance_start_unit" type="QString"/>
      <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
      <Option value="0" name="use_custom_dash" type="QString"/>
      <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties"/>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </symbols>
 </renderer-v2>
 <labeling type="rule-based">
  <rules key="{ee32b893-e549-45d7-a2ed-119687342afc}">
   <rule key="{e902c555-dc3c-47d4-a5a3-e137b1239972}" filter="&quot;inp_type&quot; IS NOT NULL">
    <settings calloutType="simple">
     <text-style textColor="0,0,0,255" fontLetterSpacing="0" fieldName="arccat_id" textOrientation="horizontal" allowHtml="0" fontFamily="Arial" blendMode="0" fontSizeMapUnitScale="3x:0,0,0,0,0,0" legendString="Aa" fontWeight="50" namedStyle="Normal" fontStrikeout="0" textOpacity="1" fontUnderline="0" fontSizeUnit="Point" useSubstitutions="0" fontKerning="1" forcedBold="0" forcedItalic="0" fontSize="8.25" fontItalic="0" fontWordSpacing="0" multilineHeight="1" capitalization="0" multilineHeightUnit="Percentage" previewBkgrdColor="255,255,255,255" isExpression="0">
      <families/>
      <text-buffer bufferSizeUnits="MM" bufferJoinStyle="128" bufferBlendMode="0" bufferNoFill="0" bufferColor="255,255,255,255" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferSize="1" bufferDraw="0" bufferOpacity="1"/>
      <text-mask maskedSymbolLayers="" maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskOpacity="1" maskJoinStyle="128" maskEnabled="0" maskSizeUnits="MM" maskType="0" maskSize="0"/>
      <background shapeRotationType="0" shapeFillColor="255,255,255,255" shapeBorderWidthUnit="MM" shapeSizeX="0" shapeSizeUnit="MM" shapeBorderColor="128,128,128,255" shapeOpacity="1" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeSizeY="0" shapeBorderWidth="0" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeSVGFile="" shapeDraw="0" shapeRadiiX="0" shapeSizeType="0" shapeOffsetX="0" shapeJoinStyle="64" shapeOffsetUnit="MM" shapeType="0" shapeRadiiY="0" shapeRotation="0" shapeOffsetY="0" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeRadiiUnit="MM" shapeBlendMode="0" shapeSizeMapUnitScale="3x:0,0,0,0,0,0">
       <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="markerSymbol" type="marker" force_rhr="0" alpha="1">
        <data_defined_properties>
         <Option type="Map">
          <Option value="" name="name" type="QString"/>
          <Option name="properties"/>
          <Option value="collection" name="type" type="QString"/>
         </Option>
        </data_defined_properties>
        <layer pass="0" locked="0" enabled="1" class="SimpleMarker">
         <Option type="Map">
          <Option value="0" name="angle" type="QString"/>
          <Option value="square" name="cap_style" type="QString"/>
          <Option value="231,113,72,255" name="color" type="QString"/>
          <Option value="1" name="horizontal_anchor_point" type="QString"/>
          <Option value="bevel" name="joinstyle" type="QString"/>
          <Option value="circle" name="name" type="QString"/>
          <Option value="0,0" name="offset" type="QString"/>
          <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
          <Option value="MM" name="offset_unit" type="QString"/>
          <Option value="35,35,35,255" name="outline_color" type="QString"/>
          <Option value="solid" name="outline_style" type="QString"/>
          <Option value="0" name="outline_width" type="QString"/>
          <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
          <Option value="MM" name="outline_width_unit" type="QString"/>
          <Option value="diameter" name="scale_method" type="QString"/>
          <Option value="2" name="size" type="QString"/>
          <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
          <Option value="MM" name="size_unit" type="QString"/>
          <Option value="1" name="vertical_anchor_point" type="QString"/>
         </Option>
         <data_defined_properties>
          <Option type="Map">
           <Option value="" name="name" type="QString"/>
           <Option name="properties"/>
           <Option value="collection" name="type" type="QString"/>
          </Option>
         </data_defined_properties>
        </layer>
       </symbol>
       <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="fillSymbol" type="fill" force_rhr="0" alpha="1">
        <data_defined_properties>
         <Option type="Map">
          <Option value="" name="name" type="QString"/>
          <Option name="properties"/>
          <Option value="collection" name="type" type="QString"/>
         </Option>
        </data_defined_properties>
        <layer pass="0" locked="0" enabled="1" class="SimpleFill">
         <Option type="Map">
          <Option value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale" type="QString"/>
          <Option value="255,255,255,255" name="color" type="QString"/>
          <Option value="bevel" name="joinstyle" type="QString"/>
          <Option value="0,0" name="offset" type="QString"/>
          <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
          <Option value="MM" name="offset_unit" type="QString"/>
          <Option value="128,128,128,255" name="outline_color" type="QString"/>
          <Option value="no" name="outline_style" type="QString"/>
          <Option value="0" name="outline_width" type="QString"/>
          <Option value="MM" name="outline_width_unit" type="QString"/>
          <Option value="solid" name="style" type="QString"/>
         </Option>
         <data_defined_properties>
          <Option type="Map">
           <Option value="" name="name" type="QString"/>
           <Option name="properties"/>
           <Option value="collection" name="type" type="QString"/>
          </Option>
         </data_defined_properties>
        </layer>
       </symbol>
      </background>
      <shadow shadowRadiusAlphaOnly="0" shadowColor="0,0,0,255" shadowBlendMode="6" shadowOffsetAngle="135" shadowOffsetUnit="MM" shadowDraw="0" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowScale="100" shadowRadiusUnit="MM" shadowOffsetGlobal="1" shadowOpacity="0.69999999999999996" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowUnder="0" shadowRadius="1.5" shadowOffsetDist="1"/>
      <dd_properties>
       <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
      </dd_properties>
      <substitutions/>
     </text-style>
     <text-format addDirectionSymbol="0" useMaxLineLengthForAutoWrap="1" placeDirectionSymbol="0" rightDirectionSymbol=">" wrapChar="" decimals="3" formatNumbers="0" plussign="0" leftDirectionSymbol="&lt;" autoWrapLength="0" multilineAlign="0" reverseDirectionSymbol="0"/>
     <placement overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" centroidInside="0" lineAnchorPercent="0.5" fitInPolygonOnly="0" xOffset="0" maxCurvedCharAngleIn="25" placement="2" priority="5" maxCurvedCharAngleOut="-25" dist="0" lineAnchorTextPoint="CenterOfText" allowDegraded="0" layerType="LineGeometry" geometryGenerator="" distUnits="MM" distMapUnitScale="3x:0,0,0,0,0,0" overrunDistance="0" yOffset="0" rotationAngle="0" repeatDistance="0" repeatDistanceUnits="MM" rotationUnit="AngleDegrees" lineAnchorType="0" lineAnchorClipping="0" offsetType="0" centroidWhole="0" quadOffset="4" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" preserveRotation="1" geometryGeneratorType="PointGeometry" polygonPlacementFlags="2" placementFlags="10" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" geometryGeneratorEnabled="0" offsetUnits="MapUnit" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" overlapHandling="PreventOverlap" overrunDistanceUnit="MM"/>
     <rendering minFeatureSize="0" scaleMax="1000" fontMaxPixelSize="10000" labelPerPart="0" scaleVisibility="1" drawLabels="1" upsidedownLabels="0" unplacedVisibility="0" obstacleFactor="1" mergeLines="0" limitNumLabels="0" scaleMin="1" maxNumLabels="2000" obstacle="1" obstacleType="0" fontLimitPixelSize="0" fontMinPixelSize="3" zIndex="0"/>
     <dd_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties"/>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </dd_properties>
     <callout type="simple">
      <Option type="Map">
       <Option value="pole_of_inaccessibility" name="anchorPoint" type="QString"/>
       <Option value="0" name="blendMode" type="int"/>
       <Option name="ddProperties" type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
       <Option value="false" name="drawToAllParts" type="bool"/>
       <Option value="0" name="enabled" type="QString"/>
       <Option value="point_on_exterior" name="labelAnchorPoint" type="QString"/>
       <Option value="&lt;symbol clip_to_extent=&quot;1&quot; is_animated=&quot;0&quot; frame_rate=&quot;10&quot; name=&quot;symbol&quot; type=&quot;line&quot; force_rhr=&quot;0&quot; alpha=&quot;1&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option value=&quot;&quot; name=&quot;name&quot; type=&quot;QString&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option value=&quot;collection&quot; name=&quot;type&quot; type=&quot;QString&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer pass=&quot;0&quot; locked=&quot;0&quot; enabled=&quot;1&quot; class=&quot;SimpleLine&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option value=&quot;0&quot; name=&quot;align_dash_pattern&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;square&quot; name=&quot;capstyle&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;5;2&quot; name=&quot;customdash&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;customdash_map_unit_scale&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;MM&quot; name=&quot;customdash_unit&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0&quot; name=&quot;dash_pattern_offset&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;dash_pattern_offset_map_unit_scale&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;MM&quot; name=&quot;dash_pattern_offset_unit&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0&quot; name=&quot;draw_inside_polygon&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;bevel&quot; name=&quot;joinstyle&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;60,60,60,255&quot; name=&quot;line_color&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;solid&quot; name=&quot;line_style&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0.3&quot; name=&quot;line_width&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;MM&quot; name=&quot;line_width_unit&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0&quot; name=&quot;offset&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;offset_map_unit_scale&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;MM&quot; name=&quot;offset_unit&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0&quot; name=&quot;ring_filter&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0&quot; name=&quot;trim_distance_end&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_end_map_unit_scale&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;MM&quot; name=&quot;trim_distance_end_unit&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0&quot; name=&quot;trim_distance_start&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_start_map_unit_scale&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;MM&quot; name=&quot;trim_distance_start_unit&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0&quot; name=&quot;tweak_dash_pattern_on_corners&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;0&quot; name=&quot;use_custom_dash&quot; type=&quot;QString&quot;/>&lt;Option value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;width_map_unit_scale&quot; type=&quot;QString&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option value=&quot;&quot; name=&quot;name&quot; type=&quot;QString&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option value=&quot;collection&quot; name=&quot;type&quot; type=&quot;QString&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>" name="lineSymbol" type="QString"/>
       <Option value="0" name="minLength" type="double"/>
       <Option value="3x:0,0,0,0,0,0" name="minLengthMapUnitScale" type="QString"/>
       <Option value="MM" name="minLengthUnit" type="QString"/>
       <Option value="0" name="offsetFromAnchor" type="double"/>
       <Option value="3x:0,0,0,0,0,0" name="offsetFromAnchorMapUnitScale" type="QString"/>
       <Option value="MM" name="offsetFromAnchorUnit" type="QString"/>
       <Option value="0" name="offsetFromLabel" type="double"/>
       <Option value="3x:0,0,0,0,0,0" name="offsetFromLabelMapUnitScale" type="QString"/>
       <Option value="MM" name="offsetFromLabelUnit" type="QString"/>
      </Option>
     </callout>
    </settings>
   </rule>
  </rules>
 </labeling>
 <customproperties>
  <Option type="Map">
   <Option value="0" name="embeddedWidgets/count" type="QString"/>
   <Option name="variableNames" type="invalid"/>
   <Option name="variableValues" type="invalid"/>
  </Option>
 </customproperties>
 <blendMode>0</blendMode>
 <featureBlendMode>0</featureBlendMode>
 <layerOpacity>1</layerOpacity>
 <SingleCategoryDiagramRenderer diagramType="Histogram" attributeLegend="1">
  <DiagramCategory barWidth="5" showAxis="1" sizeType="MM" lineSizeType="MM" lineSizeScale="3x:0,0,0,0,0,0" scaleDependency="Area" width="15" backgroundAlpha="255" penColor="#000000" height="15" diagramOrientation="Up" penWidth="0" labelPlacementMethod="XHeight" scaleBasedVisibility="0" spacingUnit="MM" spacingUnitScale="3x:0,0,0,0,0,0" minimumSize="0" rotationOffset="270" penAlpha="255" minScaleDenominator="0" spacing="5" backgroundColor="#ffffff" opacity="1" sizeScale="3x:0,0,0,0,0,0" maxScaleDenominator="0" enabled="0" direction="0">
   <fontProperties strikethrough="0" italic="0" underline="0" bold="0" description="Arial,7.8,-1,5,50,0,0,0,0,0" style=""/>
   <attribute field="" label="" colorOpacity="1" color="#000000"/>
   <axisSymbol>
    <symbol clip_to_extent="1" is_animated="0" frame_rate="10" name="" type="line" force_rhr="0" alpha="1">
     <data_defined_properties>
      <Option type="Map">
       <Option value="" name="name" type="QString"/>
       <Option name="properties"/>
       <Option value="collection" name="type" type="QString"/>
      </Option>
     </data_defined_properties>
     <layer pass="0" locked="0" enabled="1" class="SimpleLine">
      <Option type="Map">
       <Option value="0" name="align_dash_pattern" type="QString"/>
       <Option value="square" name="capstyle" type="QString"/>
       <Option value="5;2" name="customdash" type="QString"/>
       <Option value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale" type="QString"/>
       <Option value="MM" name="customdash_unit" type="QString"/>
       <Option value="0" name="dash_pattern_offset" type="QString"/>
       <Option value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale" type="QString"/>
       <Option value="MM" name="dash_pattern_offset_unit" type="QString"/>
       <Option value="0" name="draw_inside_polygon" type="QString"/>
       <Option value="bevel" name="joinstyle" type="QString"/>
       <Option value="35,35,35,255" name="line_color" type="QString"/>
       <Option value="solid" name="line_style" type="QString"/>
       <Option value="0.26" name="line_width" type="QString"/>
       <Option value="MM" name="line_width_unit" type="QString"/>
       <Option value="0" name="offset" type="QString"/>
       <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
       <Option value="MM" name="offset_unit" type="QString"/>
       <Option value="0" name="ring_filter" type="QString"/>
       <Option value="0" name="trim_distance_end" type="QString"/>
       <Option value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale" type="QString"/>
       <Option value="MM" name="trim_distance_end_unit" type="QString"/>
       <Option value="0" name="trim_distance_start" type="QString"/>
       <Option value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale" type="QString"/>
       <Option value="MM" name="trim_distance_start_unit" type="QString"/>
       <Option value="0" name="tweak_dash_pattern_on_corners" type="QString"/>
       <Option value="0" name="use_custom_dash" type="QString"/>
       <Option value="3x:0,0,0,0,0,0" name="width_map_unit_scale" type="QString"/>
      </Option>
      <data_defined_properties>
       <Option type="Map">
        <Option value="" name="name" type="QString"/>
        <Option name="properties"/>
        <Option value="collection" name="type" type="QString"/>
       </Option>
      </data_defined_properties>
     </layer>
    </symbol>
   </axisSymbol>
  </DiagramCategory>
 </SingleCategoryDiagramRenderer>
 <DiagramLayerSettings linePlacementFlags="18" obstacle="0" placement="2" dist="0" priority="0" showAll="1" zIndex="0">
  <properties>
   <Option type="Map">
    <Option value="" name="name" type="QString"/>
    <Option name="properties"/>
    <Option value="collection" name="type" type="QString"/>
   </Option>
  </properties>
 </DiagramLayerSettings>
 <geometryOptions removeDuplicateNodes="0" geometryPrecision="0">
  <activeChecks/>
  <checkConfiguration/>
 </geometryOptions>
 <legend type="default-vector" showLabelLegend="0"/>
 <referencedLayers/>
 <fieldConfiguration>
  <field name="arc_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="code" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="node_1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="nodetype_1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="y1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="custom_y1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="elev1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="custom_elev1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="sys_elev1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="sys_y1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="r1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="z1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="node_2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="nodetype_2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="y2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="custom_y2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="elev2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="custom_elev2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="sys_elev2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="sys_y2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="r2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="z2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="slope" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="arc_type" configurationFlags="None">
   <editWidget type="ValueRelation">
    <config>
     <Option type="Map">
      <Option value="False" name="AllowNull" type="QString"/>
      <Option value="" name="FilterExpression" type="QString"/>
      <Option value="id" name="Key" type="QString"/>
      <Option value="v_edit_cat_feature_arc_4cd4d71c_df9e_44bf_8911_d4932f930ad2" name="Layer" type="QString"/>
      <Option value="id" name="Value" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="sys_type" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="arccat_id" configurationFlags="None">
   <editWidget type="ValueRelation">
    <config>
     <Option type="Map">
      <Option value="False" name="AllowNull" type="QString"/>
      <Option value="" name="FilterExpression" type="QString"/>
      <Option value="id" name="Key" type="QString"/>
      <Option value="cat_arc_52f24e12_c228_47c2_b347_69b187f2d984" name="Layer" type="QString"/>
      <Option value="id" name="Value" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="matcat_id" configurationFlags="None">
   <editWidget type="ValueRelation">
    <config>
     <Option type="Map">
      <Option value="False" name="AllowNull" type="QString"/>
      <Option value="" name="FilterExpression" type="QString"/>
      <Option value="id" name="Key" type="QString"/>
      <Option value="cat_mat_arc_bba8ab41_f652_4864_95d3_45c7e39b5175" name="Layer" type="QString"/>
      <Option value="descript" name="Value" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="cat_shape" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="cat_geom1" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="cat_geom2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="cat_width" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="cat_area" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="epa_type" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="CONDUIT" name="CONDUIT" type="QString"/>
       <Option value="ORIFICE" name="ORIFICE" type="QString"/>
       <Option value="OUTLET" name="OUTLET" type="QString"/>
       <Option value="PUMP" name="PUMP" type="QString"/>
       <Option value="UNDEFINED" name="UNDEFINED" type="QString"/>
       <Option value="VIRTUAL" name="VIRTUAL" type="QString"/>
       <Option value="WEIR" name="WEIR" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="state" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="0" name="OBSOLETE" type="QString"/>
       <Option value="1" name="OPERATIVE" type="QString"/>
       <Option value="2" name="PLANIFIED" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="state_type" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="99" name="FICTICIUS" type="QString"/>
       <Option value="1" name="OBSOLETE" type="QString"/>
       <Option value="2" name="OPERATIVE" type="QString"/>
       <Option value="3" name="PLANIFIED" type="QString"/>
       <Option value="5" name="PROVISIONAL" type="QString"/>
       <Option value="4" name="RECONSTRUCT" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="expl_id" configurationFlags="None">
   <editWidget type="ValueRelation">
    <config>
     <Option type="Map">
      <Option value="False" name="AllowNull" type="QString"/>
      <Option value="" name="FilterExpression" type="QString"/>
      <Option value="expl_id" name="Key" type="QString"/>
      <Option value="v_edit_exploitation_79f9ccda_070f_4e89_b991_6f956aec4b36" name="Layer" type="QString"/>
      <Option value="name" name="Value" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="macroexpl_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="sector_id" configurationFlags="None">
   <editWidget type="ValueRelation">
    <config>
     <Option type="Map">
      <Option value="False" name="AllowNull" type="QString"/>
      <Option value="" name="FilterExpression" type="QString"/>
      <Option value="sector_id" name="Key" type="QString"/>
      <Option value="v_edit_sector_d4924986_50a2_4c42_bad8_bfff1644805d" name="Layer" type="QString"/>
      <Option value="name" name="Value" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="sector_type" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="macrosector_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="drainzone_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="drainzone_type" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="annotation" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="gis_length" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="custom_length" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="inverted_slope" configurationFlags="None">
   <editWidget type="CheckBox">
    <config>
     <Option type="Map">
      <Option value="true" name="CheckedState" type="QString"/>
      <Option value="false" name="UncheckedState" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="observ" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="comment" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="dma_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="0" name="Undefined" type="QString"/>
       <Option value="1" name="dma_01" type="QString"/>
       <Option value="3" name="dma_02" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="macrodma_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="dma_type" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="soilcat_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="soil1" name="soil1" type="QString"/>
       <Option value="soil2" name="soil2" type="QString"/>
       <Option value="soil3" name="soil3" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="function_type" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="St. Function" name="St. Function" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="category_type" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="St. Category" name="St. Category" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="fluid_type" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="St. Fluid" name="St. Fluid" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="location_type" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="St. Location" name="St. Location" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="workcat_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="workcat_id_end" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="workcat_id_plan" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="builtdate" configurationFlags="None">
   <editWidget type="DateTime">
    <config>
     <Option type="Map">
      <Option value="true" name="allow_null" type="bool"/>
      <Option value="true" name="calendar_popup" type="bool"/>
      <Option value="yyyy-MM-dd" name="display_format" type="QString"/>
      <Option value="yyyy-MM-dd" name="field_format" type="QString"/>
      <Option value="false" name="field_iso_format" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="enddate" configurationFlags="None">
   <editWidget type="DateTime">
    <config>
     <Option type="Map">
      <Option value="true" name="allow_null" type="bool"/>
      <Option value="true" name="calendar_popup" type="bool"/>
      <Option value="yyyy-MM-dd" name="display_format" type="QString"/>
      <Option value="yyyy-MM-dd" name="field_format" type="QString"/>
      <Option value="false" name="field_iso_format" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="buildercat_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="builder1" name="builder1" type="QString"/>
       <Option value="builder2" name="builder2" type="QString"/>
       <Option value="builder3" name="builder3" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="ownercat_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="owner1" name="owner1" type="QString"/>
       <Option value="owner2" name="owner2" type="QString"/>
       <Option value="owner3" name="owner3" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="muni_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="1" name="Sant Boi del Llobregat" type="QString"/>
       <Option value="2" name="Sant Esteve de les Roures" type="QString"/>
       <Option value="0" name="Undefined" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="postcode" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="district_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="1" name="Camps Blancs" type="QString"/>
       <Option value="2" name="Marianao" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="streetname" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="postnumber" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="postcomplement" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="streetname2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="postnumber2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="postcomplement2" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="region_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="1" name="Baix Llobregat" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="province_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="1" name="Barcelona" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="descript" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="link" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="verified" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="2" name="IGNORE CHECK" type="QString"/>
       <Option value="0" name="TO REVIEW" type="QString"/>
       <Option value="1" name="VERIFIED" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="undelete" configurationFlags="None">
   <editWidget type="CheckBox">
    <config>
     <Option type="Map">
      <Option value="true" name="CheckedState" type="QString"/>
      <Option value="false" name="UncheckedState" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="label" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="label_x" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="label_y" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="label_rotation" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="label_quadrant" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="publish" configurationFlags="None">
   <editWidget type="CheckBox">
    <config>
     <Option type="Map">
      <Option value="true" name="CheckedState" type="QString"/>
      <Option value="false" name="UncheckedState" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="inventory" configurationFlags="None">
   <editWidget type="CheckBox">
    <config>
     <Option type="Map">
      <Option value="true" name="CheckedState" type="QString"/>
      <Option value="false" name="UncheckedState" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="uncertain" configurationFlags="None">
   <editWidget type="CheckBox">
    <config>
     <Option type="Map">
      <Option value="true" name="CheckedState" type="QString"/>
      <Option value="false" name="UncheckedState" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="num_value" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="asset_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="pavcat_id" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="Asphalt" name="Asphalt" type="QString"/>
       <Option value="pavement1" name="pavement1" type="QString"/>
       <Option value="pavement2" name="pavement2" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="parent_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="False" name="IsMultiline" type="QString"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="expl_id2" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="" name="" type="QString"/>
       <Option value="1" name="expl_01" type="QString"/>
       <Option value="2" name="expl_02" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="is_operative" configurationFlags="None">
   <editWidget type="CheckBox">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="minsector_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="macrominsector_id" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="adate" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="adescript" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="visitability" configurationFlags="None">
   <editWidget type="ValueMap">
    <config>
     <Option type="Map">
      <Option name="map" type="Map">
       <Option value="1" name="NO VISITABLE" type="QString"/>
       <Option value="2" name="SEMI VISITABLE" type="QString"/>
       <Option value="3" name="VISITABLE" type="QString"/>
      </Option>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="tstamp" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="insert_user" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
  <field name="lastupdate" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="lastupdate_user" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option type="Map">
      <Option value="false" name="IsMultiline" type="bool"/>
     </Option>
    </config>
   </editWidget>
  </field>
  <field name="inp_type" configurationFlags="None">
   <editWidget type="TextEdit">
    <config>
     <Option/>
    </config>
   </editWidget>
  </field>
 </fieldConfiguration>
 <aliases>
  <alias field="arc_id" index="0" name="arc_id"/>
  <alias field="code" index="1" name="code"/>
  <alias field="node_1" index="2" name="node_1"/>
  <alias field="nodetype_1" index="3" name=""/>
  <alias field="y1" index="4" name="y1"/>
  <alias field="custom_y1" index="5" name="custom_y1"/>
  <alias field="elev1" index="6" name="elev1"/>
  <alias field="custom_elev1" index="7" name="custom_elev1"/>
  <alias field="sys_elev1" index="8" name="sys_elev1"/>
  <alias field="sys_y1" index="9" name="sys_y1"/>
  <alias field="r1" index="10" name="r1"/>
  <alias field="z1" index="11" name="z1"/>
  <alias field="node_2" index="12" name="node_2"/>
  <alias field="nodetype_2" index="13" name=""/>
  <alias field="y2" index="14" name="y2"/>
  <alias field="custom_y2" index="15" name="custom_y2"/>
  <alias field="elev2" index="16" name="elev2"/>
  <alias field="custom_elev2" index="17" name="custom_elev2"/>
  <alias field="sys_elev2" index="18" name="sys_elev2"/>
  <alias field="sys_y2" index="19" name="sys_y2"/>
  <alias field="r2" index="20" name="r2"/>
  <alias field="z2" index="21" name="z2"/>
  <alias field="slope" index="22" name="slope"/>
  <alias field="arc_type" index="23" name="arc_type"/>
  <alias field="sys_type" index="24" name=""/>
  <alias field="arccat_id" index="25" name="arccat_id"/>
  <alias field="matcat_id" index="26" name="matcat_id"/>
  <alias field="cat_shape" index="27" name="cat_shape"/>
  <alias field="cat_geom1" index="28" name="cat_geom1"/>
  <alias field="cat_geom2" index="29" name="cat_geom2"/>
  <alias field="cat_width" index="30" name=""/>
  <alias field="cat_area" index="31" name=""/>
  <alias field="epa_type" index="32" name="epa_type"/>
  <alias field="state" index="33" name="state"/>
  <alias field="state_type" index="34" name="state_type"/>
  <alias field="expl_id" index="35" name="expl_id"/>
  <alias field="macroexpl_id" index="36" name="Macroexploitation"/>
  <alias field="sector_id" index="37" name="sector_id"/>
  <alias field="sector_type" index="38" name=""/>
  <alias field="macrosector_id" index="39" name="macrosector_id"/>
  <alias field="drainzone_id" index="40" name="drainzone_id"/>
  <alias field="drainzone_type" index="41" name=""/>
  <alias field="annotation" index="42" name="annotation"/>
  <alias field="gis_length" index="43" name="gis_length"/>
  <alias field="custom_length" index="44" name="custom_length"/>
  <alias field="inverted_slope" index="45" name="inverted_slope"/>
  <alias field="observ" index="46" name="observ"/>
  <alias field="comment" index="47" name="comment"/>
  <alias field="dma_id" index="48" name="dma_id"/>
  <alias field="macrodma_id" index="49" name="macrodma_id"/>
  <alias field="dma_type" index="50" name=""/>
  <alias field="soilcat_id" index="51" name="soilcat_id"/>
  <alias field="function_type" index="52" name="function_type"/>
  <alias field="category_type" index="53" name="category_type"/>
  <alias field="fluid_type" index="54" name="fluid_type"/>
  <alias field="location_type" index="55" name="location_type"/>
  <alias field="workcat_id" index="56" name="workcat_id"/>
  <alias field="workcat_id_end" index="57" name="workcat_id_end"/>
  <alias field="workcat_id_plan" index="58" name="workcat_id_plan"/>
  <alias field="builtdate" index="59" name="builtdate"/>
  <alias field="enddate" index="60" name="enddate"/>
  <alias field="buildercat_id" index="61" name="buildercat_id"/>
  <alias field="ownercat_id" index="62" name="ownercat_id"/>
  <alias field="muni_id" index="63" name="muni_id"/>
  <alias field="postcode" index="64" name="postcode"/>
  <alias field="district_id" index="65" name="district"/>
  <alias field="streetname" index="66" name="streetname"/>
  <alias field="postnumber" index="67" name="postnumber"/>
  <alias field="postcomplement" index="68" name="postcomplement"/>
  <alias field="streetname2" index="69" name="streetname2"/>
  <alias field="postnumber2" index="70" name="postnumber2"/>
  <alias field="postcomplement2" index="71" name="postcomplement2"/>
  <alias field="region_id" index="72" name="Region"/>
  <alias field="province_id" index="73" name="Province"/>
  <alias field="descript" index="74" name="descript"/>
  <alias field="link" index="75" name="link"/>
  <alias field="verified" index="76" name="verified"/>
  <alias field="undelete" index="77" name="undelete"/>
  <alias field="label" index="78" name="Catalog label"/>
  <alias field="label_x" index="79" name="label_x"/>
  <alias field="label_y" index="80" name="label_y"/>
  <alias field="label_rotation" index="81" name="label_rotation"/>
  <alias field="label_quadrant" index="82" name="label_quadrant"/>
  <alias field="publish" index="83" name="publish"/>
  <alias field="inventory" index="84" name="inventory"/>
  <alias field="uncertain" index="85" name="uncertain"/>
  <alias field="num_value" index="86" name="num_value"/>
  <alias field="asset_id" index="87" name="asset_id"/>
  <alias field="pavcat_id" index="88" name="pavcat_id"/>
  <alias field="parent_id" index="89" name="parent_id"/>
  <alias field="expl_id2" index="90" name="Exploitation 2"/>
  <alias field="is_operative" index="91" name=""/>
  <alias field="minsector_id" index="92" name="minsector_id"/>
  <alias field="macrominsector_id" index="93" name="macrominsector_id"/>
  <alias field="adate" index="94" name="adate"/>
  <alias field="adescript" index="95" name="adescript"/>
  <alias field="visitability" index="96" name="Visitability"/>
  <alias field="tstamp" index="97" name="Insert tstamp"/>
  <alias field="insert_user" index="98" name=""/>
  <alias field="lastupdate" index="99" name="Last update"/>
  <alias field="lastupdate_user" index="100" name="Last update user"/>
  <alias field="inp_type" index="101" name=""/>
 </aliases>
 <defaults>
  <default field="arc_id" expression="" applyOnUpdate="0"/>
  <default field="code" expression="" applyOnUpdate="0"/>
  <default field="node_1" expression="" applyOnUpdate="0"/>
  <default field="nodetype_1" expression="" applyOnUpdate="0"/>
  <default field="y1" expression="" applyOnUpdate="0"/>
  <default field="custom_y1" expression="" applyOnUpdate="0"/>
  <default field="elev1" expression="" applyOnUpdate="0"/>
  <default field="custom_elev1" expression="" applyOnUpdate="0"/>
  <default field="sys_elev1" expression="" applyOnUpdate="0"/>
  <default field="sys_y1" expression="" applyOnUpdate="0"/>
  <default field="r1" expression="" applyOnUpdate="0"/>
  <default field="z1" expression="" applyOnUpdate="0"/>
  <default field="node_2" expression="" applyOnUpdate="0"/>
  <default field="nodetype_2" expression="" applyOnUpdate="0"/>
  <default field="y2" expression="" applyOnUpdate="0"/>
  <default field="custom_y2" expression="" applyOnUpdate="0"/>
  <default field="elev2" expression="" applyOnUpdate="0"/>
  <default field="custom_elev2" expression="" applyOnUpdate="0"/>
  <default field="sys_elev2" expression="" applyOnUpdate="0"/>
  <default field="sys_y2" expression="" applyOnUpdate="0"/>
  <default field="r2" expression="" applyOnUpdate="0"/>
  <default field="z2" expression="" applyOnUpdate="0"/>
  <default field="slope" expression="" applyOnUpdate="0"/>
  <default field="arc_type" expression="" applyOnUpdate="0"/>
  <default field="sys_type" expression="" applyOnUpdate="0"/>
  <default field="arccat_id" expression="" applyOnUpdate="0"/>
  <default field="matcat_id" expression="" applyOnUpdate="0"/>
  <default field="cat_shape" expression="" applyOnUpdate="0"/>
  <default field="cat_geom1" expression="" applyOnUpdate="0"/>
  <default field="cat_geom2" expression="" applyOnUpdate="0"/>
  <default field="cat_width" expression="" applyOnUpdate="0"/>
  <default field="cat_area" expression="" applyOnUpdate="0"/>
  <default field="epa_type" expression="" applyOnUpdate="0"/>
  <default field="state" expression="" applyOnUpdate="0"/>
  <default field="state_type" expression="" applyOnUpdate="0"/>
  <default field="expl_id" expression="" applyOnUpdate="0"/>
  <default field="macroexpl_id" expression="" applyOnUpdate="0"/>
  <default field="sector_id" expression="" applyOnUpdate="0"/>
  <default field="sector_type" expression="" applyOnUpdate="0"/>
  <default field="macrosector_id" expression="" applyOnUpdate="0"/>
  <default field="drainzone_id" expression="" applyOnUpdate="0"/>
  <default field="drainzone_type" expression="" applyOnUpdate="0"/>
  <default field="annotation" expression="" applyOnUpdate="0"/>
  <default field="gis_length" expression="" applyOnUpdate="0"/>
  <default field="custom_length" expression="" applyOnUpdate="0"/>
  <default field="inverted_slope" expression="" applyOnUpdate="0"/>
  <default field="observ" expression="" applyOnUpdate="0"/>
  <default field="comment" expression="" applyOnUpdate="0"/>
  <default field="dma_id" expression="" applyOnUpdate="0"/>
  <default field="macrodma_id" expression="" applyOnUpdate="0"/>
  <default field="dma_type" expression="" applyOnUpdate="0"/>
  <default field="soilcat_id" expression="" applyOnUpdate="0"/>
  <default field="function_type" expression="" applyOnUpdate="0"/>
  <default field="category_type" expression="" applyOnUpdate="0"/>
  <default field="fluid_type" expression="" applyOnUpdate="0"/>
  <default field="location_type" expression="" applyOnUpdate="0"/>
  <default field="workcat_id" expression="" applyOnUpdate="0"/>
  <default field="workcat_id_end" expression="" applyOnUpdate="0"/>
  <default field="workcat_id_plan" expression="" applyOnUpdate="0"/>
  <default field="builtdate" expression="" applyOnUpdate="0"/>
  <default field="enddate" expression="" applyOnUpdate="0"/>
  <default field="buildercat_id" expression="" applyOnUpdate="0"/>
  <default field="ownercat_id" expression="" applyOnUpdate="0"/>
  <default field="muni_id" expression="" applyOnUpdate="0"/>
  <default field="postcode" expression="" applyOnUpdate="0"/>
  <default field="district_id" expression="" applyOnUpdate="0"/>
  <default field="streetname" expression="" applyOnUpdate="0"/>
  <default field="postnumber" expression="" applyOnUpdate="0"/>
  <default field="postcomplement" expression="" applyOnUpdate="0"/>
  <default field="streetname2" expression="" applyOnUpdate="0"/>
  <default field="postnumber2" expression="" applyOnUpdate="0"/>
  <default field="postcomplement2" expression="" applyOnUpdate="0"/>
  <default field="region_id" expression="" applyOnUpdate="0"/>
  <default field="province_id" expression="" applyOnUpdate="0"/>
  <default field="descript" expression="" applyOnUpdate="0"/>
  <default field="link" expression="" applyOnUpdate="0"/>
  <default field="verified" expression="" applyOnUpdate="0"/>
  <default field="undelete" expression="" applyOnUpdate="0"/>
  <default field="label" expression="" applyOnUpdate="0"/>
  <default field="label_x" expression="" applyOnUpdate="0"/>
  <default field="label_y" expression="" applyOnUpdate="0"/>
  <default field="label_rotation" expression="" applyOnUpdate="0"/>
  <default field="label_quadrant" expression="" applyOnUpdate="0"/>
  <default field="publish" expression="" applyOnUpdate="0"/>
  <default field="inventory" expression="" applyOnUpdate="0"/>
  <default field="uncertain" expression="" applyOnUpdate="0"/>
  <default field="num_value" expression="" applyOnUpdate="0"/>
  <default field="asset_id" expression="" applyOnUpdate="0"/>
  <default field="pavcat_id" expression="" applyOnUpdate="0"/>
  <default field="parent_id" expression="" applyOnUpdate="0"/>
  <default field="expl_id2" expression="" applyOnUpdate="0"/>
  <default field="is_operative" expression="" applyOnUpdate="0"/>
  <default field="minsector_id" expression="" applyOnUpdate="0"/>
  <default field="macrominsector_id" expression="" applyOnUpdate="0"/>
  <default field="adate" expression="" applyOnUpdate="0"/>
  <default field="adescript" expression="" applyOnUpdate="0"/>
  <default field="visitability" expression="" applyOnUpdate="0"/>
  <default field="tstamp" expression="" applyOnUpdate="0"/>
  <default field="insert_user" expression="" applyOnUpdate="0"/>
  <default field="lastupdate" expression="" applyOnUpdate="0"/>
  <default field="lastupdate_user" expression="" applyOnUpdate="0"/>
  <default field="inp_type" expression="" applyOnUpdate="0"/>
 </defaults>
 <constraints>
  <constraint field="arc_id" unique_strength="1" notnull_strength="1" exp_strength="0" constraints="3"/>
  <constraint field="code" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="node_1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="nodetype_1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="y1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="custom_y1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="elev1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="custom_elev1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="sys_elev1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="sys_y1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="r1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="z1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="node_2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="nodetype_2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="y2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="custom_y2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="elev2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="custom_elev2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="sys_elev2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="sys_y2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="r2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="z2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="slope" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="arc_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="sys_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="arccat_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="matcat_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="cat_shape" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="cat_geom1" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="cat_geom2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="cat_width" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="cat_area" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="epa_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="state" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="state_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="expl_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="macroexpl_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="sector_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="sector_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="macrosector_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="drainzone_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="drainzone_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="annotation" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="gis_length" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="custom_length" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="inverted_slope" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="observ" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="comment" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="dma_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="macrodma_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="dma_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="soilcat_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="function_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="category_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="fluid_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="location_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="workcat_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="workcat_id_end" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="workcat_id_plan" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="builtdate" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="enddate" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="buildercat_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="ownercat_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="muni_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="postcode" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="district_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="streetname" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="postnumber" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="postcomplement" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="streetname2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="postnumber2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="postcomplement2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="region_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="province_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="descript" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="link" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="verified" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="undelete" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="label" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="label_x" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="label_y" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="label_rotation" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="label_quadrant" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="publish" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="inventory" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="uncertain" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="num_value" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="asset_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="pavcat_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="parent_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="expl_id2" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="is_operative" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="minsector_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="macrominsector_id" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="adate" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="adescript" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="visitability" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="tstamp" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="insert_user" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="lastupdate" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="lastupdate_user" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
  <constraint field="inp_type" unique_strength="0" notnull_strength="0" exp_strength="0" constraints="0"/>
 </constraints>
 <constraintExpressions>
  <constraint field="arc_id" desc="" exp=""/>
  <constraint field="code" desc="" exp=""/>
  <constraint field="node_1" desc="" exp=""/>
  <constraint field="nodetype_1" desc="" exp=""/>
  <constraint field="y1" desc="" exp=""/>
  <constraint field="custom_y1" desc="" exp=""/>
  <constraint field="elev1" desc="" exp=""/>
  <constraint field="custom_elev1" desc="" exp=""/>
  <constraint field="sys_elev1" desc="" exp=""/>
  <constraint field="sys_y1" desc="" exp=""/>
  <constraint field="r1" desc="" exp=""/>
  <constraint field="z1" desc="" exp=""/>
  <constraint field="node_2" desc="" exp=""/>
  <constraint field="nodetype_2" desc="" exp=""/>
  <constraint field="y2" desc="" exp=""/>
  <constraint field="custom_y2" desc="" exp=""/>
  <constraint field="elev2" desc="" exp=""/>
  <constraint field="custom_elev2" desc="" exp=""/>
  <constraint field="sys_elev2" desc="" exp=""/>
  <constraint field="sys_y2" desc="" exp=""/>
  <constraint field="r2" desc="" exp=""/>
  <constraint field="z2" desc="" exp=""/>
  <constraint field="slope" desc="" exp=""/>
  <constraint field="arc_type" desc="" exp=""/>
  <constraint field="sys_type" desc="" exp=""/>
  <constraint field="arccat_id" desc="" exp=""/>
  <constraint field="matcat_id" desc="" exp=""/>
  <constraint field="cat_shape" desc="" exp=""/>
  <constraint field="cat_geom1" desc="" exp=""/>
  <constraint field="cat_geom2" desc="" exp=""/>
  <constraint field="cat_width" desc="" exp=""/>
  <constraint field="cat_area" desc="" exp=""/>
  <constraint field="epa_type" desc="" exp=""/>
  <constraint field="state" desc="" exp=""/>
  <constraint field="state_type" desc="" exp=""/>
  <constraint field="expl_id" desc="" exp=""/>
  <constraint field="macroexpl_id" desc="" exp=""/>
  <constraint field="sector_id" desc="" exp=""/>
  <constraint field="sector_type" desc="" exp=""/>
  <constraint field="macrosector_id" desc="" exp=""/>
  <constraint field="drainzone_id" desc="" exp=""/>
  <constraint field="drainzone_type" desc="" exp=""/>
  <constraint field="annotation" desc="" exp=""/>
  <constraint field="gis_length" desc="" exp=""/>
  <constraint field="custom_length" desc="" exp=""/>
  <constraint field="inverted_slope" desc="" exp=""/>
  <constraint field="observ" desc="" exp=""/>
  <constraint field="comment" desc="" exp=""/>
  <constraint field="dma_id" desc="" exp=""/>
  <constraint field="macrodma_id" desc="" exp=""/>
  <constraint field="dma_type" desc="" exp=""/>
  <constraint field="soilcat_id" desc="" exp=""/>
  <constraint field="function_type" desc="" exp=""/>
  <constraint field="category_type" desc="" exp=""/>
  <constraint field="fluid_type" desc="" exp=""/>
  <constraint field="location_type" desc="" exp=""/>
  <constraint field="workcat_id" desc="" exp=""/>
  <constraint field="workcat_id_end" desc="" exp=""/>
  <constraint field="workcat_id_plan" desc="" exp=""/>
  <constraint field="builtdate" desc="" exp=""/>
  <constraint field="enddate" desc="" exp=""/>
  <constraint field="buildercat_id" desc="" exp=""/>
  <constraint field="ownercat_id" desc="" exp=""/>
  <constraint field="muni_id" desc="" exp=""/>
  <constraint field="postcode" desc="" exp=""/>
  <constraint field="district_id" desc="" exp=""/>
  <constraint field="streetname" desc="" exp=""/>
  <constraint field="postnumber" desc="" exp=""/>
  <constraint field="postcomplement" desc="" exp=""/>
  <constraint field="streetname2" desc="" exp=""/>
  <constraint field="postnumber2" desc="" exp=""/>
  <constraint field="postcomplement2" desc="" exp=""/>
  <constraint field="region_id" desc="" exp=""/>
  <constraint field="province_id" desc="" exp=""/>
  <constraint field="descript" desc="" exp=""/>
  <constraint field="link" desc="" exp=""/>
  <constraint field="verified" desc="" exp=""/>
  <constraint field="undelete" desc="" exp=""/>
  <constraint field="label" desc="" exp=""/>
  <constraint field="label_x" desc="" exp=""/>
  <constraint field="label_y" desc="" exp=""/>
  <constraint field="label_rotation" desc="" exp=""/>
  <constraint field="label_quadrant" desc="" exp=""/>
  <constraint field="publish" desc="" exp=""/>
  <constraint field="inventory" desc="" exp=""/>
  <constraint field="uncertain" desc="" exp=""/>
  <constraint field="num_value" desc="" exp=""/>
  <constraint field="asset_id" desc="" exp=""/>
  <constraint field="pavcat_id" desc="" exp=""/>
  <constraint field="parent_id" desc="" exp=""/>
  <constraint field="expl_id2" desc="" exp=""/>
  <constraint field="is_operative" desc="" exp=""/>
  <constraint field="minsector_id" desc="" exp=""/>
  <constraint field="macrominsector_id" desc="" exp=""/>
  <constraint field="adate" desc="" exp=""/>
  <constraint field="adescript" desc="" exp=""/>
  <constraint field="visitability" desc="" exp=""/>
  <constraint field="tstamp" desc="" exp=""/>
  <constraint field="insert_user" desc="" exp=""/>
  <constraint field="lastupdate" desc="" exp=""/>
  <constraint field="lastupdate_user" desc="" exp=""/>
  <constraint field="inp_type" desc="" exp=""/>
 </constraintExpressions>
 <expressionfields/>
 <attributeactions>
  <defaultAction value="{00000000-0000-0000-0000-000000000000}" key="Canvas"/>
 </attributeactions>
 <attributetableconfig sortOrder="0" actionWidgetStyle="dropDown" sortExpression="">
  <columns>
   <column hidden="0" width="-1" name="arc_id" type="field"/>
   <column hidden="0" width="-1" name="code" type="field"/>
   <column hidden="0" width="-1" name="node_1" type="field"/>
   <column hidden="0" width="-1" name="nodetype_1" type="field"/>
   <column hidden="0" width="-1" name="y1" type="field"/>
   <column hidden="0" width="-1" name="custom_y1" type="field"/>
   <column hidden="0" width="-1" name="elev1" type="field"/>
   <column hidden="0" width="-1" name="custom_elev1" type="field"/>
   <column hidden="0" width="-1" name="sys_elev1" type="field"/>
   <column hidden="0" width="-1" name="sys_y1" type="field"/>
   <column hidden="0" width="-1" name="r1" type="field"/>
   <column hidden="0" width="-1" name="z1" type="field"/>
   <column hidden="0" width="-1" name="node_2" type="field"/>
   <column hidden="0" width="-1" name="nodetype_2" type="field"/>
   <column hidden="0" width="-1" name="y2" type="field"/>
   <column hidden="0" width="-1" name="custom_y2" type="field"/>
   <column hidden="0" width="-1" name="elev2" type="field"/>
   <column hidden="0" width="-1" name="custom_elev2" type="field"/>
   <column hidden="0" width="-1" name="sys_elev2" type="field"/>
   <column hidden="0" width="-1" name="sys_y2" type="field"/>
   <column hidden="0" width="-1" name="r2" type="field"/>
   <column hidden="0" width="-1" name="z2" type="field"/>
   <column hidden="0" width="-1" name="slope" type="field"/>
   <column hidden="0" width="-1" name="arc_type" type="field"/>
   <column hidden="0" width="-1" name="sys_type" type="field"/>
   <column hidden="0" width="-1" name="arccat_id" type="field"/>
   <column hidden="0" width="-1" name="matcat_id" type="field"/>
   <column hidden="0" width="-1" name="cat_shape" type="field"/>
   <column hidden="0" width="-1" name="cat_geom1" type="field"/>
   <column hidden="0" width="-1" name="cat_geom2" type="field"/>
   <column hidden="0" width="-1" name="cat_width" type="field"/>
   <column hidden="0" width="-1" name="cat_area" type="field"/>
   <column hidden="0" width="-1" name="epa_type" type="field"/>
   <column hidden="0" width="-1" name="state" type="field"/>
   <column hidden="0" width="-1" name="state_type" type="field"/>
   <column hidden="0" width="-1" name="expl_id" type="field"/>
   <column hidden="0" width="-1" name="macroexpl_id" type="field"/>
   <column hidden="0" width="-1" name="sector_id" type="field"/>
   <column hidden="0" width="-1" name="sector_type" type="field"/>
   <column hidden="0" width="-1" name="macrosector_id" type="field"/>
   <column hidden="0" width="-1" name="drainzone_id" type="field"/>
   <column hidden="0" width="-1" name="drainzone_type" type="field"/>
   <column hidden="0" width="-1" name="annotation" type="field"/>
   <column hidden="0" width="-1" name="gis_length" type="field"/>
   <column hidden="0" width="-1" name="custom_length" type="field"/>
   <column hidden="0" width="-1" name="inverted_slope" type="field"/>
   <column hidden="0" width="-1" name="observ" type="field"/>
   <column hidden="0" width="-1" name="comment" type="field"/>
   <column hidden="0" width="-1" name="dma_id" type="field"/>
   <column hidden="0" width="-1" name="macrodma_id" type="field"/>
   <column hidden="0" width="-1" name="dma_type" type="field"/>
   <column hidden="0" width="-1" name="soilcat_id" type="field"/>
   <column hidden="0" width="-1" name="function_type" type="field"/>
   <column hidden="0" width="-1" name="category_type" type="field"/>
   <column hidden="0" width="-1" name="fluid_type" type="field"/>
   <column hidden="0" width="-1" name="location_type" type="field"/>
   <column hidden="0" width="-1" name="workcat_id" type="field"/>
   <column hidden="0" width="-1" name="workcat_id_end" type="field"/>
   <column hidden="0" width="-1" name="workcat_id_plan" type="field"/>
   <column hidden="0" width="-1" name="builtdate" type="field"/>
   <column hidden="0" width="-1" name="enddate" type="field"/>
   <column hidden="0" width="-1" name="buildercat_id" type="field"/>
   <column hidden="0" width="-1" name="ownercat_id" type="field"/>
   <column hidden="0" width="-1" name="muni_id" type="field"/>
   <column hidden="0" width="-1" name="postcode" type="field"/>
   <column hidden="0" width="-1" name="district_id" type="field"/>
   <column hidden="0" width="-1" name="streetname" type="field"/>
   <column hidden="0" width="-1" name="postnumber" type="field"/>
   <column hidden="0" width="-1" name="postcomplement" type="field"/>
   <column hidden="0" width="-1" name="streetname2" type="field"/>
   <column hidden="0" width="-1" name="postnumber2" type="field"/>
   <column hidden="0" width="-1" name="postcomplement2" type="field"/>
   <column hidden="0" width="-1" name="region_id" type="field"/>
   <column hidden="0" width="-1" name="province_id" type="field"/>
   <column hidden="0" width="-1" name="descript" type="field"/>
   <column hidden="0" width="-1" name="link" type="field"/>
   <column hidden="0" width="-1" name="verified" type="field"/>
   <column hidden="0" width="-1" name="undelete" type="field"/>
   <column hidden="0" width="-1" name="label" type="field"/>
   <column hidden="0" width="-1" name="label_x" type="field"/>
   <column hidden="0" width="-1" name="label_y" type="field"/>
   <column hidden="0" width="-1" name="label_rotation" type="field"/>
   <column hidden="0" width="-1" name="label_quadrant" type="field"/>
   <column hidden="0" width="-1" name="publish" type="field"/>
   <column hidden="0" width="-1" name="inventory" type="field"/>
   <column hidden="0" width="-1" name="uncertain" type="field"/>
   <column hidden="0" width="-1" name="num_value" type="field"/>
   <column hidden="0" width="-1" name="asset_id" type="field"/>
   <column hidden="0" width="-1" name="pavcat_id" type="field"/>
   <column hidden="0" width="-1" name="parent_id" type="field"/>
   <column hidden="0" width="-1" name="expl_id2" type="field"/>
   <column hidden="0" width="-1" name="is_operative" type="field"/>
   <column hidden="0" width="-1" name="minsector_id" type="field"/>
   <column hidden="0" width="-1" name="macrominsector_id" type="field"/>
   <column hidden="0" width="-1" name="adate" type="field"/>
   <column hidden="0" width="-1" name="adescript" type="field"/>
   <column hidden="0" width="-1" name="visitability" type="field"/>
   <column hidden="0" width="-1" name="tstamp" type="field"/>
   <column hidden="0" width="-1" name="insert_user" type="field"/>
   <column hidden="0" width="-1" name="lastupdate" type="field"/>
   <column hidden="0" width="-1" name="lastupdate_user" type="field"/>
   <column hidden="0" width="-1" name="inp_type" type="field"/>
   <column hidden="1" width="-1" type="actions"/>
  </columns>
 </attributetableconfig>
 <conditionalstyles>
  <rowstyles/>
  <fieldstyles/>
 </conditionalstyles>
 <storedexpressions/>
 <editform tolerant="1"></editform>
 <editforminit/>
 <editforminitcodesource>0</editforminitcodesource>
 <editforminitfilepath></editforminitfilepath>
 <editforminitcode><![CDATA[# -*- codificación: utf-8 -*-
"""
Los formularios de QGIS pueden tener una función de Python que
es llamada cuando se abre el formulario.

Use esta función para añadir lógica extra a sus formularios.

Introduzca el nombre de la función en el campo
"Python Init function".
Sigue un ejemplo:
"""
from qgis.PyQt.QtWidgets import QWidget

def my_form_open(dialog, layer, feature):
	geom = feature.geometry()
	control = dialog.findChild(QWidget, "MyLineEdit")
]]></editforminitcode>
 <featformsuppress>0</featformsuppress>
 <editorlayout>generatedlayout</editorlayout>
 <editable>
  <field name="adate" editable="1"/>
  <field name="adescript" editable="1"/>
  <field name="annotation" editable="1"/>
  <field name="arc_id" editable="1"/>
  <field name="arc_type" editable="1"/>
  <field name="arccat_id" editable="1"/>
  <field name="asset_id" editable="1"/>
  <field name="buildercat_id" editable="1"/>
  <field name="builtdate" editable="1"/>
  <field name="cat_area" editable="1"/>
  <field name="cat_geom1" editable="1"/>
  <field name="cat_geom2" editable="1"/>
  <field name="cat_shape" editable="1"/>
  <field name="cat_width" editable="1"/>
  <field name="category_type" editable="1"/>
  <field name="code" editable="1"/>
  <field name="comment" editable="1"/>
  <field name="custom_elev1" editable="1"/>
  <field name="custom_elev2" editable="1"/>
  <field name="custom_length" editable="1"/>
  <field name="custom_y1" editable="1"/>
  <field name="custom_y2" editable="1"/>
  <field name="descript" editable="1"/>
  <field name="district_id" editable="1"/>
  <field name="dma_id" editable="1"/>
  <field name="dma_type" editable="1"/>
  <field name="drainzone_id" editable="1"/>
  <field name="drainzone_type" editable="1"/>
  <field name="elev1" editable="1"/>
  <field name="elev2" editable="1"/>
  <field name="enddate" editable="1"/>
  <field name="epa_type" editable="1"/>
  <field name="expl_id" editable="1"/>
  <field name="expl_id2" editable="1"/>
  <field name="fluid_type" editable="1"/>
  <field name="function_type" editable="1"/>
  <field name="gis_length" editable="1"/>
  <field name="inp_type" editable="1"/>
  <field name="insert_user" editable="1"/>
  <field name="inventory" editable="1"/>
  <field name="inverted_slope" editable="1"/>
  <field name="is_operative" editable="1"/>
  <field name="label" editable="1"/>
  <field name="label_quadrant" editable="1"/>
  <field name="label_rotation" editable="1"/>
  <field name="label_x" editable="1"/>
  <field name="label_y" editable="1"/>
  <field name="lastupdate" editable="1"/>
  <field name="lastupdate_user" editable="1"/>
  <field name="link" editable="1"/>
  <field name="location_type" editable="1"/>
  <field name="macrodma_id" editable="1"/>
  <field name="macroexpl_id" editable="1"/>
  <field name="macrominsector_id" editable="1"/>
  <field name="macrosector_id" editable="1"/>
  <field name="matcat_id" editable="1"/>
  <field name="minsector_id" editable="1"/>
  <field name="muni_id" editable="1"/>
  <field name="node_1" editable="1"/>
  <field name="node_2" editable="1"/>
  <field name="nodetype_1" editable="1"/>
  <field name="nodetype_2" editable="1"/>
  <field name="num_value" editable="1"/>
  <field name="observ" editable="1"/>
  <field name="ownercat_id" editable="1"/>
  <field name="parent_id" editable="1"/>
  <field name="pavcat_id" editable="1"/>
  <field name="postcode" editable="1"/>
  <field name="postcomplement" editable="1"/>
  <field name="postcomplement2" editable="1"/>
  <field name="postnumber" editable="1"/>
  <field name="postnumber2" editable="1"/>
  <field name="province_id" editable="1"/>
  <field name="publish" editable="1"/>
  <field name="r1" editable="1"/>
  <field name="r2" editable="1"/>
  <field name="region_id" editable="1"/>
  <field name="sector_id" editable="1"/>
  <field name="sector_type" editable="1"/>
  <field name="slope" editable="1"/>
  <field name="soilcat_id" editable="1"/>
  <field name="state" editable="1"/>
  <field name="state_type" editable="1"/>
  <field name="streetname" editable="1"/>
  <field name="streetname2" editable="1"/>
  <field name="sys_elev1" editable="1"/>
  <field name="sys_elev2" editable="1"/>
  <field name="sys_type" editable="1"/>
  <field name="sys_y1" editable="1"/>
  <field name="sys_y2" editable="1"/>
  <field name="tstamp" editable="1"/>
  <field name="uncertain" editable="1"/>
  <field name="undelete" editable="1"/>
  <field name="verified" editable="1"/>
  <field name="visitability" editable="1"/>
  <field name="workcat_id" editable="1"/>
  <field name="workcat_id_end" editable="1"/>
  <field name="workcat_id_plan" editable="1"/>
  <field name="y1" editable="1"/>
  <field name="y2" editable="1"/>
  <field name="z1" editable="1"/>
  <field name="z2" editable="1"/>
 </editable>
 <labelOnTop>
  <field labelOnTop="0" name="adate"/>
  <field labelOnTop="0" name="adescript"/>
  <field labelOnTop="0" name="annotation"/>
  <field labelOnTop="0" name="arc_id"/>
  <field labelOnTop="0" name="arc_type"/>
  <field labelOnTop="0" name="arccat_id"/>
  <field labelOnTop="0" name="asset_id"/>
  <field labelOnTop="0" name="buildercat_id"/>
  <field labelOnTop="0" name="builtdate"/>
  <field labelOnTop="0" name="cat_area"/>
  <field labelOnTop="0" name="cat_geom1"/>
  <field labelOnTop="0" name="cat_geom2"/>
  <field labelOnTop="0" name="cat_shape"/>
  <field labelOnTop="0" name="cat_width"/>
  <field labelOnTop="0" name="category_type"/>
  <field labelOnTop="0" name="code"/>
  <field labelOnTop="0" name="comment"/>
  <field labelOnTop="0" name="custom_elev1"/>
  <field labelOnTop="0" name="custom_elev2"/>
  <field labelOnTop="0" name="custom_length"/>
  <field labelOnTop="0" name="custom_y1"/>
  <field labelOnTop="0" name="custom_y2"/>
  <field labelOnTop="0" name="descript"/>
  <field labelOnTop="0" name="district_id"/>
  <field labelOnTop="0" name="dma_id"/>
  <field labelOnTop="0" name="dma_type"/>
  <field labelOnTop="0" name="drainzone_id"/>
  <field labelOnTop="0" name="drainzone_type"/>
  <field labelOnTop="0" name="elev1"/>
  <field labelOnTop="0" name="elev2"/>
  <field labelOnTop="0" name="enddate"/>
  <field labelOnTop="0" name="epa_type"/>
  <field labelOnTop="0" name="expl_id"/>
  <field labelOnTop="0" name="expl_id2"/>
  <field labelOnTop="0" name="fluid_type"/>
  <field labelOnTop="0" name="function_type"/>
  <field labelOnTop="0" name="gis_length"/>
  <field labelOnTop="0" name="inp_type"/>
  <field labelOnTop="0" name="insert_user"/>
  <field labelOnTop="0" name="inventory"/>
  <field labelOnTop="0" name="inverted_slope"/>
  <field labelOnTop="0" name="is_operative"/>
  <field labelOnTop="0" name="label"/>
  <field labelOnTop="0" name="label_quadrant"/>
  <field labelOnTop="0" name="label_rotation"/>
  <field labelOnTop="0" name="label_x"/>
  <field labelOnTop="0" name="label_y"/>
  <field labelOnTop="0" name="lastupdate"/>
  <field labelOnTop="0" name="lastupdate_user"/>
  <field labelOnTop="0" name="link"/>
  <field labelOnTop="0" name="location_type"/>
  <field labelOnTop="0" name="macrodma_id"/>
  <field labelOnTop="0" name="macroexpl_id"/>
  <field labelOnTop="0" name="macrominsector_id"/>
  <field labelOnTop="0" name="macrosector_id"/>
  <field labelOnTop="0" name="matcat_id"/>
  <field labelOnTop="0" name="minsector_id"/>
  <field labelOnTop="0" name="muni_id"/>
  <field labelOnTop="0" name="node_1"/>
  <field labelOnTop="0" name="node_2"/>
  <field labelOnTop="0" name="nodetype_1"/>
  <field labelOnTop="0" name="nodetype_2"/>
  <field labelOnTop="0" name="num_value"/>
  <field labelOnTop="0" name="observ"/>
  <field labelOnTop="0" name="ownercat_id"/>
  <field labelOnTop="0" name="parent_id"/>
  <field labelOnTop="0" name="pavcat_id"/>
  <field labelOnTop="0" name="postcode"/>
  <field labelOnTop="0" name="postcomplement"/>
  <field labelOnTop="0" name="postcomplement2"/>
  <field labelOnTop="0" name="postnumber"/>
  <field labelOnTop="0" name="postnumber2"/>
  <field labelOnTop="0" name="province_id"/>
  <field labelOnTop="0" name="publish"/>
  <field labelOnTop="0" name="r1"/>
  <field labelOnTop="0" name="r2"/>
  <field labelOnTop="0" name="region_id"/>
  <field labelOnTop="0" name="sector_id"/>
  <field labelOnTop="0" name="sector_type"/>
  <field labelOnTop="0" name="slope"/>
  <field labelOnTop="0" name="soilcat_id"/>
  <field labelOnTop="0" name="state"/>
  <field labelOnTop="0" name="state_type"/>
  <field labelOnTop="0" name="streetname"/>
  <field labelOnTop="0" name="streetname2"/>
  <field labelOnTop="0" name="sys_elev1"/>
  <field labelOnTop="0" name="sys_elev2"/>
  <field labelOnTop="0" name="sys_type"/>
  <field labelOnTop="0" name="sys_y1"/>
  <field labelOnTop="0" name="sys_y2"/>
  <field labelOnTop="0" name="tstamp"/>
  <field labelOnTop="0" name="uncertain"/>
  <field labelOnTop="0" name="undelete"/>
  <field labelOnTop="0" name="verified"/>
  <field labelOnTop="0" name="visitability"/>
  <field labelOnTop="0" name="workcat_id"/>
  <field labelOnTop="0" name="workcat_id_end"/>
  <field labelOnTop="0" name="workcat_id_plan"/>
  <field labelOnTop="0" name="y1"/>
  <field labelOnTop="0" name="y2"/>
  <field labelOnTop="0" name="z1"/>
  <field labelOnTop="0" name="z2"/>
 </labelOnTop>
 <reuseLastValue>
  <field name="adate" reuseLastValue="0"/>
  <field name="adescript" reuseLastValue="0"/>
  <field name="annotation" reuseLastValue="0"/>
  <field name="arc_id" reuseLastValue="0"/>
  <field name="arc_type" reuseLastValue="0"/>
  <field name="arccat_id" reuseLastValue="0"/>
  <field name="asset_id" reuseLastValue="0"/>
  <field name="buildercat_id" reuseLastValue="0"/>
  <field name="builtdate" reuseLastValue="0"/>
  <field name="cat_area" reuseLastValue="0"/>
  <field name="cat_geom1" reuseLastValue="0"/>
  <field name="cat_geom2" reuseLastValue="0"/>
  <field name="cat_shape" reuseLastValue="0"/>
  <field name="cat_width" reuseLastValue="0"/>
  <field name="category_type" reuseLastValue="0"/>
  <field name="code" reuseLastValue="0"/>
  <field name="comment" reuseLastValue="0"/>
  <field name="custom_elev1" reuseLastValue="0"/>
  <field name="custom_elev2" reuseLastValue="0"/>
  <field name="custom_length" reuseLastValue="0"/>
  <field name="custom_y1" reuseLastValue="0"/>
  <field name="custom_y2" reuseLastValue="0"/>
  <field name="descript" reuseLastValue="0"/>
  <field name="district_id" reuseLastValue="0"/>
  <field name="dma_id" reuseLastValue="0"/>
  <field name="dma_type" reuseLastValue="0"/>
  <field name="drainzone_id" reuseLastValue="0"/>
  <field name="drainzone_type" reuseLastValue="0"/>
  <field name="elev1" reuseLastValue="0"/>
  <field name="elev2" reuseLastValue="0"/>
  <field name="enddate" reuseLastValue="0"/>
  <field name="epa_type" reuseLastValue="0"/>
  <field name="expl_id" reuseLastValue="0"/>
  <field name="expl_id2" reuseLastValue="0"/>
  <field name="fluid_type" reuseLastValue="0"/>
  <field name="function_type" reuseLastValue="0"/>
  <field name="gis_length" reuseLastValue="0"/>
  <field name="inp_type" reuseLastValue="0"/>
  <field name="insert_user" reuseLastValue="0"/>
  <field name="inventory" reuseLastValue="0"/>
  <field name="inverted_slope" reuseLastValue="0"/>
  <field name="is_operative" reuseLastValue="0"/>
  <field name="label" reuseLastValue="0"/>
  <field name="label_quadrant" reuseLastValue="0"/>
  <field name="label_rotation" reuseLastValue="0"/>
  <field name="label_x" reuseLastValue="0"/>
  <field name="label_y" reuseLastValue="0"/>
  <field name="lastupdate" reuseLastValue="0"/>
  <field name="lastupdate_user" reuseLastValue="0"/>
  <field name="link" reuseLastValue="0"/>
  <field name="location_type" reuseLastValue="0"/>
  <field name="macrodma_id" reuseLastValue="0"/>
  <field name="macroexpl_id" reuseLastValue="0"/>
  <field name="macrominsector_id" reuseLastValue="0"/>
  <field name="macrosector_id" reuseLastValue="0"/>
  <field name="matcat_id" reuseLastValue="0"/>
  <field name="minsector_id" reuseLastValue="0"/>
  <field name="muni_id" reuseLastValue="0"/>
  <field name="node_1" reuseLastValue="0"/>
  <field name="node_2" reuseLastValue="0"/>
  <field name="nodetype_1" reuseLastValue="0"/>
  <field name="nodetype_2" reuseLastValue="0"/>
  <field name="num_value" reuseLastValue="0"/>
  <field name="observ" reuseLastValue="0"/>
  <field name="ownercat_id" reuseLastValue="0"/>
  <field name="parent_id" reuseLastValue="0"/>
  <field name="pavcat_id" reuseLastValue="0"/>
  <field name="postcode" reuseLastValue="0"/>
  <field name="postcomplement" reuseLastValue="0"/>
  <field name="postcomplement2" reuseLastValue="0"/>
  <field name="postnumber" reuseLastValue="0"/>
  <field name="postnumber2" reuseLastValue="0"/>
  <field name="province_id" reuseLastValue="0"/>
  <field name="publish" reuseLastValue="0"/>
  <field name="r1" reuseLastValue="0"/>
  <field name="r2" reuseLastValue="0"/>
  <field name="region_id" reuseLastValue="0"/>
  <field name="sector_id" reuseLastValue="0"/>
  <field name="sector_type" reuseLastValue="0"/>
  <field name="slope" reuseLastValue="0"/>
  <field name="soilcat_id" reuseLastValue="0"/>
  <field name="state" reuseLastValue="0"/>
  <field name="state_type" reuseLastValue="0"/>
  <field name="streetname" reuseLastValue="0"/>
  <field name="streetname2" reuseLastValue="0"/>
  <field name="sys_elev1" reuseLastValue="0"/>
  <field name="sys_elev2" reuseLastValue="0"/>
  <field name="sys_type" reuseLastValue="0"/>
  <field name="sys_y1" reuseLastValue="0"/>
  <field name="sys_y2" reuseLastValue="0"/>
  <field name="tstamp" reuseLastValue="0"/>
  <field name="uncertain" reuseLastValue="0"/>
  <field name="undelete" reuseLastValue="0"/>
  <field name="verified" reuseLastValue="0"/>
  <field name="visitability" reuseLastValue="0"/>
  <field name="workcat_id" reuseLastValue="0"/>
  <field name="workcat_id_end" reuseLastValue="0"/>
  <field name="workcat_id_plan" reuseLastValue="0"/>
  <field name="y1" reuseLastValue="0"/>
  <field name="y2" reuseLastValue="0"/>
  <field name="z1" reuseLastValue="0"/>
  <field name="z2" reuseLastValue="0"/>
 </reuseLastValue>
 <dataDefinedFieldProperties/>
 <widgets/>
 <previewExpression>"streetname"</previewExpression>
 <mapTip></mapTip>
 <layerGeometryType>1</layerGeometryType>
</qgis>
')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('102', 've_node', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.28.4-Firenze" styleCategories="Symbology">
  <renderer-v2 enableorderby="0" forceraster="0" symbollevels="0" type="RuleRenderer" referencescale="-1">
    <rules key="{2b70c7cf-3215-47bb-be52-2168a74bf823}">
      <rule key="{3c19d0bd-e4a9-460c-8e13-d4ebabe76cde}" label="JUNCTION" filter="&quot;inp_type&quot; = ''JUNCTION''" symbol="0"/>
      <rule key="{53ff0c3f-982c-414b-9b96-5c2191b0da78}" label="NETGULLY" filter="&quot;inp_type&quot; = ''NETGULLY''" symbol="1"/>
      <rule key="{dc169491-eb61-4958-894f-6224db06045c}" label="OUTFALL" filter="&quot;inp_type&quot; = ''OUTFALL''" symbol="2"/>
      <rule key="{09224b9c-f6fe-4624-aea0-bc86a447066e}" label="STORAGE" filter="&quot;inp_type&quot; = ''STORAGE''" symbol="3"/>
      <rule key="{35746168-286d-42fa-b920-573a171f6484}" label="DIVIDER" filter="&quot;inp_type&quot; = ''DIVIDER''" symbol="4"/>
      <rule key="{a8309ef2-dcc4-402a-90eb-522eb5bdeb56}" label="NOT USED" filter="&quot;inp_type&quot; IS NULL" symbol="5"/>
    </rules>
    <symbols>
      <symbol force_rhr="0" alpha="1" clip_to_extent="1" is_animated="0" frame_rate="10" name="0" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" enabled="1" pass="0" class="SimpleMarker">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="31,120,180,255" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="0,0,0,255" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0.2" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2.2" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" alpha="1" clip_to_extent="1" is_animated="0" frame_rate="10" name="1" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" enabled="1" pass="0" class="SimpleMarker">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="255,255,255,255" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="0,0,0,255" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0.2" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="area" name="scale_method" type="QString"/>
            <Option value="2.4" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" enabled="1" pass="0" class="SimpleMarker">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="0,0,0,255" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="0,0,0,255" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0.4" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="area" name="scale_method" type="QString"/>
            <Option value="0.525" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" alpha="1" clip_to_extent="1" is_animated="0" frame_rate="10" name="2" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" enabled="1" pass="0" class="SimpleMarker">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="72,123,182,255" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="triangle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="50,87,128,255" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0.4" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2.4" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" alpha="1" clip_to_extent="1" is_animated="0" frame_rate="10" name="3" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" enabled="1" pass="0" class="SimpleMarker">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="31,120,180,255" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="square" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="0,0,0,255" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2.7" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option value="false" name="active" type="bool"/>
                  <Option value="1" name="type" type="int"/>
                  <Option value="" name="val" type="QString"/>
                </Option>
              </Option>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" alpha="1" clip_to_extent="1" is_animated="0" frame_rate="10" name="4" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" enabled="1" pass="0" class="SimpleMarker">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="72,123,182,255" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="diamond" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="50,87,128,255" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0.4" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="2.6" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol force_rhr="0" alpha="1" clip_to_extent="1" is_animated="0" frame_rate="10" name="5" type="marker">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" name="name" type="QString"/>
            <Option name="properties"/>
            <Option value="collection" name="type" type="QString"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" enabled="1" pass="0" class="SimpleMarker">
          <Option type="Map">
            <Option value="0" name="angle" type="QString"/>
            <Option value="square" name="cap_style" type="QString"/>
            <Option value="215,215,215,255" name="color" type="QString"/>
            <Option value="1" name="horizontal_anchor_point" type="QString"/>
            <Option value="bevel" name="joinstyle" type="QString"/>
            <Option value="circle" name="name" type="QString"/>
            <Option value="0,0" name="offset" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="offset_map_unit_scale" type="QString"/>
            <Option value="MM" name="offset_unit" type="QString"/>
            <Option value="215,215,215,255" name="outline_color" type="QString"/>
            <Option value="solid" name="outline_style" type="QString"/>
            <Option value="0.4" name="outline_width" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale" type="QString"/>
            <Option value="MM" name="outline_width_unit" type="QString"/>
            <Option value="diameter" name="scale_method" type="QString"/>
            <Option value="1.6" name="size" type="QString"/>
            <Option value="3x:0,0,0,0,0,0" name="size_map_unit_scale" type="QString"/>
            <Option value="MM" name="size_unit" type="QString"/>
            <Option value="1" name="vertical_anchor_point" type="QString"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" name="name" type="QString"/>
              <Option name="properties"/>
              <Option value="collection" name="type" type="QString"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('105', 'point', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.40.6-Bratislava">
  <renderer-v2 enableorderby="0" type="RuleRenderer" referencescale="-1" forceraster="0" symbollevels="0">
    <rules key="{e4d87f5e-3fd2-4d97-8962-998d1cba9adf}">
      <rule label="Connec" filter="&quot;feature_type&quot; = ''CONNEC'' and  &quot;stream_type&quot;  =  ''mainstream'' " key="{9c94b1b8-8153-4cce-b198-b2bda93a93d6}" symbol="0"/>
      <rule label="Gully mainstream" filter=" &quot;feature_type&quot;  = ''GULLY'' and  &quot;stream_type&quot;  =  ''mainstream'' " key="{979e0699-2e15-403a-9c69-e30227975796}" symbol="1"/>
      <rule label="Node mainstream" filter=" &quot;feature_type&quot;  = ''NODE'' and  &quot;stream_type&quot;  =  ''mainstream'' " key="{a38e0b7e-b58a-4a05-baab-8018a82d3727}" symbol="2"/>
      <rule label="Connec diverted flow" filter="&quot;feature_type&quot; = ''CONNEC'' and  &quot;stream_type&quot; = ''diverted flow''" key="{b32d9276-a77a-4179-8d27-2b2015c5b2f1}" symbol="3"/>
      <rule label="Gully diverted flow" filter=" &quot;feature_type&quot;  = ''GULLY'' and  &quot;stream_type&quot;  =  ''diverted flow''" key="{10fed0c0-d299-4d2f-b388-0722768847f0}" symbol="4"/>
      <rule label="Node diverted flow" filter=" &quot;feature_type&quot;  = ''NODE'' and  &quot;stream_type&quot;  =  ''diverted flow''" key="{26c49b63-1fab-4676-afc2-37a7b531592c}" symbol="5"/>
    </rules>
    <symbols>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="0" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="45" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="255,120,79,255,hsv:0.03888888888888889,0.69019607843137254,1,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="cross_fill" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="255,60,0,255,hsv:0.03888888888888889,1,1,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="1.6" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="1" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="255,120,79,255,hsv:0.03888888888888889,0.69019607843137254,1,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="square" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="255,60,0,255,hsv:0.03888888888888889,1,1,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="1.4" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="2" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="255,120,79,255,hsv:0.03888888888888889,0.69019607843137254,1,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="circle" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="255,60,0,255,hsv:0.03888888888888889,1,1,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="2.6" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="3" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="45" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="0,211,46,255,hsv:0.36969444444444444,1,0.82893110551613647,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="cross_fill" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="2,141,32,255,hsv:0.36969444444444444,0.98834210727092398,0.55385671778439005,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="1.6" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="4" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="0,211,46,255,hsv:0.36969444444444444,1,0.82893110551613647,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="square" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="2,141,32,255,hsv:0.36969444444444444,0.98834210727092398,0.55385671778439005,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="1.4" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="5" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="0,211,46,255,hsv:0.36969444444444444,1,0.82893110551613647,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="circle" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="2,141,32,255,hsv:0.36969444444444444,0.98834210727092398,0.55385671778439005,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="2.6" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option value="" type="QString" name="name"/>
        <Option name="properties"/>
        <Option value="collection" type="QString" name="type"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{7ed4929a-7cce-4761-af88-aa2a8b1c9a42}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="255,0,0,255,rgb:1,0,0,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="circle" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="2" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('106', 'point', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.40.6-Bratislava">
  <renderer-v2 enableorderby="0" type="RuleRenderer" referencescale="-1" forceraster="0" symbollevels="0">
    <rules key="{e4d87f5e-3fd2-4d97-8962-998d1cba9adf}">
      <rule label="Connec" filter="&quot;feature_type&quot; = ''CONNEC'' and  &quot;stream_type&quot;  =  ''mainstream'' " key="{9c94b1b8-8153-4cce-b198-b2bda93a93d6}" symbol="0"/>
      <rule label="Gully mainstream" filter=" &quot;feature_type&quot;  = ''GULLY'' and  &quot;stream_type&quot;  =  ''mainstream'' " key="{979e0699-2e15-403a-9c69-e30227975796}" symbol="1"/>
      <rule label="Node mainstream" filter=" &quot;feature_type&quot;  = ''NODE'' and  &quot;stream_type&quot;  =  ''mainstream'' " key="{a38e0b7e-b58a-4a05-baab-8018a82d3727}" symbol="2"/>
      <rule label="Connec diverted flow" filter="&quot;feature_type&quot; = ''CONNEC'' and  &quot;stream_type&quot; = ''diverted flow''" key="{b32d9276-a77a-4179-8d27-2b2015c5b2f1}" symbol="3"/>
      <rule label="Gully diverted flow" filter=" &quot;feature_type&quot;  = ''GULLY'' and  &quot;stream_type&quot;  =  ''diverted flow''" key="{10fed0c0-d299-4d2f-b388-0722768847f0}" symbol="4"/>
      <rule label="Node diverted flow" filter=" &quot;feature_type&quot;  = ''NODE'' and  &quot;stream_type&quot;  =  ''diverted flow''" key="{26c49b63-1fab-4676-afc2-37a7b531592c}" symbol="5"/>
    </rules>
    <symbols>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="0" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="45" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="255,120,79,255,hsv:0.03888888888888889,0.69019607843137254,1,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="cross_fill" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="255,60,0,255,hsv:0.03888888888888889,1,1,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="1.6" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="1" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="255,120,79,255,hsv:0.03888888888888889,0.69019607843137254,1,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="square" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="255,60,0,255,hsv:0.03888888888888889,1,1,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="1.4" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="2" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="255,120,79,255,hsv:0.03888888888888889,0.69019607843137254,1,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="circle" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="255,60,0,255,hsv:0.03888888888888889,1,1,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="2.6" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="3" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="45" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="0,211,46,255,hsv:0.36969444444444444,1,0.82893110551613647,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="cross_fill" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="2,141,32,255,hsv:0.36969444444444444,0.98834210727092398,0.55385671778439005,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="1.6" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="4" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="0,211,46,255,hsv:0.36969444444444444,1,0.82893110551613647,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="square" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="2,141,32,255,hsv:0.36969444444444444,0.98834210727092398,0.55385671778439005,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="1.4" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="5" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{b59dc6ec-7c58-4c2a-9fc3-28518bed91a3}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="0,211,46,255,hsv:0.36969444444444444,1,0.82893110551613647,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="circle" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="2,141,32,255,hsv:0.36969444444444444,0.98834210727092398,0.55385671778439005,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="2.6" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option value="" type="QString" name="name"/>
        <Option name="properties"/>
        <Option value="collection" type="QString" name="type"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol alpha="1" type="marker" clip_to_extent="1" is_animated="0" name="" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option value="" type="QString" name="name"/>
            <Option name="properties"/>
            <Option value="collection" type="QString" name="type"/>
          </Option>
        </data_defined_properties>
        <layer id="{7ed4929a-7cce-4761-af88-aa2a8b1c9a42}" class="SimpleMarker" locked="0" enabled="1" pass="0">
          <Option type="Map">
            <Option value="0" type="QString" name="angle"/>
            <Option value="square" type="QString" name="cap_style"/>
            <Option value="255,0,0,255,rgb:1,0,0,1" type="QString" name="color"/>
            <Option value="1" type="QString" name="horizontal_anchor_point"/>
            <Option value="bevel" type="QString" name="joinstyle"/>
            <Option value="circle" type="QString" name="name"/>
            <Option value="0,0" type="QString" name="offset"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="offset_map_unit_scale"/>
            <Option value="MM" type="QString" name="offset_unit"/>
            <Option value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" type="QString" name="outline_color"/>
            <Option value="solid" type="QString" name="outline_style"/>
            <Option value="0" type="QString" name="outline_width"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="outline_width_map_unit_scale"/>
            <Option value="MM" type="QString" name="outline_width_unit"/>
            <Option value="diameter" type="QString" name="scale_method"/>
            <Option value="2" type="QString" name="size"/>
            <Option value="3x:0,0,0,0,0,0" type="QString" name="size_map_unit_scale"/>
            <Option value="MM" type="QString" name="size_unit"/>
            <Option value="1" type="QString" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('106', 've_node', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.22.4-Białowieża">
  <renderer-v2 forceraster="0" referencescale="-1" symbollevels="0" type="RuleRenderer" enableorderby="0">
    <rules key="{726173c1-e48a-4505-bde5-b50ffb7bba39}">
      <rule filter="&quot;sys_type&quot; = ''STORAGE''" symbol="0" scalemaxdenom="25000" label="Storage" key="{d22d6bf4-55db-4cb5-8b49-25a3c52a3d1b}"/>
      <rule filter="&quot;sys_type&quot; = ''CHAMBER''" symbol="1" scalemaxdenom="25000" label="Chamber" key="{2ad49ef6-10ef-413f-9dc9-82ff5a236362}"/>
      <rule filter="&quot;sys_type&quot; = ''WWTP''" symbol="2" scalemaxdenom="25000" label="Wwtp" key="{fbe58f73-553d-4064-8e10-43eed3ee776f}"/>
      <rule filter="&quot;sys_type&quot; = ''NETGULLY''" symbol="3" scalemaxdenom="10000" label="Netgully" key="{93522d7c-98e1-4e5f-a8ed-62fd17ca4f1f}"/>
      <rule filter="&quot;sys_type&quot; = ''NETELEMENT''" symbol="4" scalemaxdenom="10000" label="Netelement" key="{e9f34e9b-5335-4553-aad1-8f52fb4b7fd9}"/>
      <rule filter="&quot;sys_type&quot; = ''MANHOLE''" symbol="5" scalemaxdenom="10000" label="Manhole" key="{c4d73b40-d93d-4ba0-b066-ff35c7a380fa}"/>
      <rule filter="&quot;sys_type&quot; = ''NETINIT''" symbol="6" scalemaxdenom="10000" label="Netinit" key="{ab7634fb-6056-43cb-b569-bed1e561bc34}"/>
      <rule filter="&quot;sys_type&quot; = ''WJUMP''" symbol="7" scalemaxdenom="10000" label="Wjump" key="{010803db-b772-4cda-b196-1767fa88163b}"/>
      <rule filter="&quot;sys_type&quot; = ''JUNCTION''" symbol="8" scalemaxdenom="10000" label="Junction" key="{1aea5824-3d04-41eb-9016-bc26e1c51f00}"/>
      <rule filter="&quot;sys_type&quot; = ''OUTFALL''" symbol="9" scalemaxdenom="10000" label="Outfall" key="{be5b7b53-a9d4-4085-af09-11a3194dacd4}"/>
      <rule filter="&quot;sys_type&quot; = ''VALVE''" symbol="10" scalemaxdenom="10000" label="Valve" key="{75dd03f5-eb03-4155-8f29-0179198c1276}"/>
    </rules>
    <symbols>
      <symbol name="0" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="44,67,207,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="44,67,207,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="1" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="31,120,180,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="31,120,180,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="10" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,0,0,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="255,255,255,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="0,0,0,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="255,255,255,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="2" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="50,48,55,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="50,48,55,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,0,0,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="0,0,0,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="3" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="106,233,255,0"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="1.8"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="4" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="129,10,78,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="129,10,78,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="5" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="106,233,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="6" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="26,115,162,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="26,115,162,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="4"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="7" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="147,218,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="147,218,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="147,218,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="0.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="147,218,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="0.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="8" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="45,136,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="45,136,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="0.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="255,0,0,0"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="0.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="9" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="227,26,28,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="filled_arrowhead"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="227,26,28,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="filled_arrowhead"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('107', 've_node', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.22.4-Białowieża">
  <renderer-v2 forceraster="0" referencescale="-1" symbollevels="0" type="RuleRenderer" enableorderby="0">
    <rules key="{726173c1-e48a-4505-bde5-b50ffb7bba39}">
      <rule filter="&quot;sys_type&quot; = ''STORAGE''" symbol="0" scalemaxdenom="25000" label="Storage" key="{d22d6bf4-55db-4cb5-8b49-25a3c52a3d1b}"/>
      <rule filter="&quot;sys_type&quot; = ''CHAMBER''" symbol="1" scalemaxdenom="25000" label="Chamber" key="{2ad49ef6-10ef-413f-9dc9-82ff5a236362}"/>
      <rule filter="&quot;sys_type&quot; = ''WWTP''" symbol="2" scalemaxdenom="25000" label="Wwtp" key="{fbe58f73-553d-4064-8e10-43eed3ee776f}"/>
      <rule filter="&quot;sys_type&quot; = ''NETGULLY''" symbol="3" scalemaxdenom="10000" label="Netgully" key="{93522d7c-98e1-4e5f-a8ed-62fd17ca4f1f}"/>
      <rule filter="&quot;sys_type&quot; = ''NETELEMENT''" symbol="4" scalemaxdenom="10000" label="Netelement" key="{e9f34e9b-5335-4553-aad1-8f52fb4b7fd9}"/>
      <rule filter="&quot;sys_type&quot; = ''MANHOLE''" symbol="5" scalemaxdenom="10000" label="Manhole" key="{c4d73b40-d93d-4ba0-b066-ff35c7a380fa}"/>
      <rule filter="&quot;sys_type&quot; = ''NETINIT''" symbol="6" scalemaxdenom="10000" label="Netinit" key="{ab7634fb-6056-43cb-b569-bed1e561bc34}"/>
      <rule filter="&quot;sys_type&quot; = ''WJUMP''" symbol="7" scalemaxdenom="10000" label="Wjump" key="{010803db-b772-4cda-b196-1767fa88163b}"/>
      <rule filter="&quot;sys_type&quot; = ''JUNCTION''" symbol="8" scalemaxdenom="10000" label="Junction" key="{1aea5824-3d04-41eb-9016-bc26e1c51f00}"/>
      <rule filter="&quot;sys_type&quot; = ''OUTFALL''" symbol="9" scalemaxdenom="10000" label="Outfall" key="{be5b7b53-a9d4-4085-af09-11a3194dacd4}"/>
      <rule filter="&quot;sys_type&quot; = ''VALVE''" symbol="10" scalemaxdenom="10000" label="Valve" key="{75dd03f5-eb03-4155-8f29-0179198c1276}"/>
    </rules>
    <symbols>
      <symbol name="0" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="44,67,207,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="44,67,207,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="1" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="31,120,180,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="31,120,180,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="10" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,0,0,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="255,255,255,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="0,0,0,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="255,255,255,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="2" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="50,48,55,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="50,48,55,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,0,0,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="0,0,0,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="3" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="106,233,255,0"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="1.8"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="4" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="129,10,78,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="129,10,78,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="5" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="106,233,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="6" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="26,115,162,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="26,115,162,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="4"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="7" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="147,218,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="147,218,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="147,218,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="0.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="147,218,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="0.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="8" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="45,136,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="45,136,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="0.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="255,0,0,0"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="0.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="9" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="227,26,28,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="filled_arrowhead"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="227,26,28,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="filled_arrowhead"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('108', 've_node', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology" version="3.22.4-Białowieża">
  <renderer-v2 forceraster="0" referencescale="-1" symbollevels="0" type="RuleRenderer" enableorderby="0">
    <rules key="{726173c1-e48a-4505-bde5-b50ffb7bba39}">
      <rule filter="&quot;sys_type&quot; = ''STORAGE''" symbol="0" scalemaxdenom="25000" label="Storage" key="{d22d6bf4-55db-4cb5-8b49-25a3c52a3d1b}"/>
      <rule filter="&quot;sys_type&quot; = ''CHAMBER''" symbol="1" scalemaxdenom="25000" label="Chamber" key="{2ad49ef6-10ef-413f-9dc9-82ff5a236362}"/>
      <rule filter="&quot;sys_type&quot; = ''WWTP''" symbol="2" scalemaxdenom="25000" label="Wwtp" key="{fbe58f73-553d-4064-8e10-43eed3ee776f}"/>
      <rule filter="&quot;sys_type&quot; = ''NETGULLY''" symbol="3" scalemaxdenom="10000" label="Netgully" key="{93522d7c-98e1-4e5f-a8ed-62fd17ca4f1f}"/>
      <rule filter="&quot;sys_type&quot; = ''NETELEMENT''" symbol="4" scalemaxdenom="10000" label="Netelement" key="{e9f34e9b-5335-4553-aad1-8f52fb4b7fd9}"/>
      <rule filter="&quot;sys_type&quot; = ''MANHOLE''" symbol="5" scalemaxdenom="10000" label="Manhole" key="{c4d73b40-d93d-4ba0-b066-ff35c7a380fa}"/>
      <rule filter="&quot;sys_type&quot; = ''NETINIT''" symbol="6" scalemaxdenom="10000" label="Netinit" key="{ab7634fb-6056-43cb-b569-bed1e561bc34}"/>
      <rule filter="&quot;sys_type&quot; = ''WJUMP''" symbol="7" scalemaxdenom="10000" label="Wjump" key="{010803db-b772-4cda-b196-1767fa88163b}"/>
      <rule filter="&quot;sys_type&quot; = ''JUNCTION''" symbol="8" scalemaxdenom="10000" label="Junction" key="{1aea5824-3d04-41eb-9016-bc26e1c51f00}"/>
      <rule filter="&quot;sys_type&quot; = ''OUTFALL''" symbol="9" scalemaxdenom="10000" label="Outfall" key="{be5b7b53-a9d4-4085-af09-11a3194dacd4}"/>
      <rule filter="&quot;sys_type&quot; = ''VALVE''" symbol="10" scalemaxdenom="10000" label="Valve" key="{75dd03f5-eb03-4155-8f29-0179198c1276}"/>
    </rules>
    <symbols>
      <symbol name="0" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="44,67,207,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="44,67,207,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="1" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="31,120,180,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="31,120,180,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="10" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,0,0,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="255,255,255,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="0,0,0,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="255,255,255,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="2" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="50,48,55,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="50,48,55,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="square"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.5"/>
                      <Option name="maxValue" type="double" value="25000"/>
                      <Option name="minSize" type="double" value="4.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,0,0,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="0,0,0,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="3" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="106,233,255,0"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="1.8"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="4" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="129,10,78,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="129,10,78,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="5" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="106,233,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="6" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="26,115,162,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="26,115,162,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="4"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="7" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="147,218,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="147,218,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="147,218,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="0.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="147,218,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="0.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="8" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="45,136,255,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="45,136,255,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="2"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="0.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="255,0,0,0"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="circle"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="0.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol name="9" alpha="1" clip_to_extent="1" type="marker" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer class="SimpleMarker" pass="0" enabled="1" locked="0">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="227,26,28,255"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="filled_arrowhead"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <prop k="angle" v="0"/>
          <prop k="cap_style" v="square"/>
          <prop k="color" v="227,26,28,255"/>
          <prop k="horizontal_anchor_point" v="1"/>
          <prop k="joinstyle" v="bevel"/>
          <prop k="name" v="filled_arrowhead"/>
          <prop k="offset" v="0,0"/>
          <prop k="offset_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="offset_unit" v="MM"/>
          <prop k="outline_color" v="0,0,0,255"/>
          <prop k="outline_style" v="solid"/>
          <prop k="outline_width" v="0"/>
          <prop k="outline_width_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="outline_width_unit" v="MM"/>
          <prop k="scale_method" v="diameter"/>
          <prop k="size" v="3.5"/>
          <prop k="size_map_unit_scale" v="3x:0,0,0,0,0,0"/>
          <prop k="size_unit" v="MM"/>
          <prop k="vertical_anchor_point" v="1"/>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
  </renderer-v2>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('110', 'v_plan_psector', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis version="3.40.7-Bratislava" styleCategories="Symbology">
 <renderer-v2 forceraster="0" type="RuleRenderer" symbollevels="0" referencescale="-1" enableorderby="0">
  <rules key="{27c5bcf5-31ab-4680-a34f-7d1469258a0b}">
   <rule key="{acd8b33b-d1cb-4560-9912-677a5b67bb73}" symbol="1" label="Active" filter="active is true"/>
   <rule key="{1a5745ef-3db0-447b-916c-16f80c5fad2f}" symbol="2" label="Inactive" filter="active is not true"/>
   <rule key="{d7963222-1f79-4e3c-81c2-99095fc5484b}" symbol="0" label="Archived" filter="status in (5,6,7)"/>
  </rules>
  <symbols>
   <symbol frame_rate="10" type="fill" clip_to_extent="1" is_animated="0" force_rhr="0" name="0" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option type="QString" value="" name="name"/>
      <Option name="properties"/>
      <Option type="QString" value="collection" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleFill" id="{da502e84-2255-4840-b89b-b703671034aa}" locked="0" pass="0" enabled="1">
     <Option type="Map">
      <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
      <Option type="QString" value="203,203,203,255,rgb:0.79607843137254897,0.79607843137254897,0.79607843137254897,1" name="color"/>
      <Option type="QString" value="bevel" name="joinstyle"/>
      <Option type="QString" value="0,0" name="offset"/>
      <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
      <Option type="QString" value="MM" name="offset_unit"/>
      <Option type="QString" value="203,203,203,255,hsv:0.82013888888888886,0,0.79452201113908594,1" name="outline_color"/>
      <Option type="QString" value="solid" name="outline_style"/>
      <Option type="QString" value="0.75" name="outline_width"/>
      <Option type="QString" value="MM" name="outline_width_unit"/>
      <Option type="QString" value="b_diagonal" name="style"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" value="" name="name"/>
       <Option name="properties"/>
       <Option type="QString" value="collection" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol frame_rate="10" type="fill" clip_to_extent="1" is_animated="0" force_rhr="0" name="1" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option type="QString" value="" name="name"/>
      <Option name="properties"/>
      <Option type="QString" value="collection" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleFill" id="{da502e84-2255-4840-b89b-b703671034aa}" locked="0" pass="0" enabled="1">
     <Option type="Map">
      <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
      <Option type="QString" value="227,92,92,63,rgb:0.8901960784313725,0.36078431372549019,0.36078431372549019,0.24705882352941178" name="color"/>
      <Option type="QString" value="bevel" name="joinstyle"/>
      <Option type="QString" value="0,0" name="offset"/>
      <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
      <Option type="QString" value="MM" name="offset_unit"/>
      <Option type="QString" value="0,202,0,255,hsv:0.33333333333333331,1,0.792156862745098,1" name="outline_color"/>
      <Option type="QString" value="solid" name="outline_style"/>
      <Option type="QString" value="0.75" name="outline_width"/>
      <Option type="QString" value="MM" name="outline_width_unit"/>
      <Option type="QString" value="no" name="style"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" value="" name="name"/>
       <Option name="properties"/>
       <Option type="QString" value="collection" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
   <symbol frame_rate="10" type="fill" clip_to_extent="1" is_animated="0" force_rhr="0" name="2" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option type="QString" value="" name="name"/>
      <Option name="properties"/>
      <Option type="QString" value="collection" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleFill" id="{da502e84-2255-4840-b89b-b703671034aa}" locked="0" pass="0" enabled="1">
     <Option type="Map">
      <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
      <Option type="QString" value="227,92,92,63,rgb:0.8901960784313725,0.36078431372549019,0.36078431372549019,0.24705882352941178" name="color"/>
      <Option type="QString" value="bevel" name="joinstyle"/>
      <Option type="QString" value="0,0" name="offset"/>
      <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
      <Option type="QString" value="MM" name="offset_unit"/>
      <Option type="QString" value="255,149,0,255,rgb:1,0.58431372549019611,0,1" name="outline_color"/>
      <Option type="QString" value="solid" name="outline_style"/>
      <Option type="QString" value="0.75" name="outline_width"/>
      <Option type="QString" value="MM" name="outline_width_unit"/>
      <Option type="QString" value="no" name="style"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" value="" name="name"/>
       <Option name="properties"/>
       <Option type="QString" value="collection" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </symbols>
  <data-defined-properties>
   <Option type="Map">
    <Option type="QString" value="" name="name"/>
    <Option name="properties"/>
    <Option type="QString" value="collection" name="type"/>
   </Option>
  </data-defined-properties>
 </renderer-v2>
 <selection mode="Default">
  <selectionColor invalid="1"/>
  <selectionSymbol>
   <symbol frame_rate="10" type="fill" clip_to_extent="1" is_animated="0" force_rhr="0" name="" alpha="1">
    <data_defined_properties>
     <Option type="Map">
      <Option type="QString" value="" name="name"/>
      <Option name="properties"/>
      <Option type="QString" value="collection" name="type"/>
     </Option>
    </data_defined_properties>
    <layer class="SimpleFill" id="{323b1679-e9a1-4444-89e5-7be9913c57d8}" locked="0" pass="0" enabled="1">
     <Option type="Map">
      <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
      <Option type="QString" value="0,0,255,255,rgb:0,0,1,1" name="color"/>
      <Option type="QString" value="bevel" name="joinstyle"/>
      <Option type="QString" value="0,0" name="offset"/>
      <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
      <Option type="QString" value="MM" name="offset_unit"/>
      <Option type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1" name="outline_color"/>
      <Option type="QString" value="solid" name="outline_style"/>
      <Option type="QString" value="0.26" name="outline_width"/>
      <Option type="QString" value="MM" name="outline_width_unit"/>
      <Option type="QString" value="solid" name="style"/>
     </Option>
     <data_defined_properties>
      <Option type="Map">
       <Option type="QString" value="" name="name"/>
       <Option name="properties"/>
       <Option type="QString" value="collection" name="type"/>
      </Option>
     </data_defined_properties>
    </layer>
   </symbol>
  </selectionSymbol>
 </selection>
 <blendMode>0</blendMode>
 <featureBlendMode>0</featureBlendMode>
 <layerGeometryType>2</layerGeometryType>
</qgis>
')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('110', 've_arc', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis labelsEnabled="0" version="3.40.8-Bratislava" styleCategories="Symbology|Labeling">
  <renderer-v2 symbollevels="0" type="RuleRenderer" referencescale="-1" enableorderby="0" forceraster="0">
    <rules key="{4134ea89-8b48-46ac-8a3d-b0847733e30d}">
      <rule key="{75138ec7-4c1d-4368-bdd4-96db18a460d0}" label="OBSOLETE" filter="state = 0" symbol="0"/>
      <rule key="{6088b14d-8a83-4586-a9a0-c774d674bbce}" label="OPERATIVE" filter="state = 1 AND (p_state&lt;>0 or p_state is null)" symbol="1"/>
      <rule key="{2968ab80-f16f-442f-afbc-b2b8f71864e3}" label="PLANIFIED" filter="state = 2" symbol="2"/>
      <rule key="{9a47325e-1c67-436a-af26-2a78ff9c0a13}" label="PHASE-OUT" filter="state = 1 AND p_state = 0" symbol="3"/>
      <rule key="{9f77ea61-3fb4-4654-942c-2ef19d8ce21d}" label="(drawing)" filter="ELSE" symbol="4"/>
    </rules>
    <symbols>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="0" type="line" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{125567a8-a047-460b-9af5-14ba91bb9a69}" class="SimpleLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="align_dash_pattern" type="QString" value="0"/>
            <Option name="capstyle" type="QString" value="square"/>
            <Option name="customdash" type="QString" value="5;2"/>
            <Option name="customdash_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="customdash_unit" type="QString" value="MM"/>
            <Option name="dash_pattern_offset" type="QString" value="0"/>
            <Option name="dash_pattern_offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="dash_pattern_offset_unit" type="QString" value="MM"/>
            <Option name="draw_inside_polygon" type="QString" value="0"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="line_color" type="QString" value="162,162,162,255,rgb:0.63682001983672842,0.63682001983672842,0.63682001983672842,1"/>
            <Option name="line_style" type="QString" value="solid"/>
            <Option name="line_width" type="QString" value="0.36"/>
            <Option name="line_width_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="trim_distance_end" type="QString" value="0"/>
            <Option name="trim_distance_end_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_end_unit" type="QString" value="MM"/>
            <Option name="trim_distance_start" type="QString" value="0"/>
            <Option name="trim_distance_start_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_start_unit" type="QString" value="MM"/>
            <Option name="tweak_dash_pattern_on_corners" type="QString" value="0"/>
            <Option name="use_custom_dash" type="QString" value="0"/>
            <Option name="width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{867127f5-d842-49bc-9fe7-f0c443d7eb32}" class="MarkerLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="average_angle_length" type="QString" value="4"/>
            <Option name="average_angle_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="average_angle_unit" type="QString" value="MM"/>
            <Option name="interval" type="QString" value="3"/>
            <Option name="interval_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="interval_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_along_line" type="QString" value="0"/>
            <Option name="offset_along_line_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_along_line_unit" type="QString" value="MM"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="place_on_every_part" type="bool" value="true"/>
            <Option name="placements" type="QString" value="CentralPoint"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="rotate" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" force_rhr="0" frame_rate="10" name="@0@1" type="marker" alpha="1" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="{8ffd9947-55a5-4c75-8756-c2fe1b12e838}" class="SimpleMarker" pass="0" enabled="1">
              <Option type="Map">
                <Option name="angle" type="QString" value="0"/>
                <Option name="cap_style" type="QString" value="square"/>
                <Option name="color" type="QString" value="162,162,162,255,rgb:0.63682001983672842,0.63682001983672842,0.63682001983672842,1"/>
                <Option name="horizontal_anchor_point" type="QString" value="1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="name" type="QString" value="filled_arrowhead"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
                <Option name="outline_style" type="QString" value="solid"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="outline_width_unit" type="QString" value="MM"/>
                <Option name="scale_method" type="QString" value="diameter"/>
                <Option name="size" type="QString" value="2.56"/>
                <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="size_unit" type="QString" value="MM"/>
                <Option name="vertical_anchor_point" type="QString" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties" type="Map">
                    <Option name="size" type="Map">
                      <Option name="active" type="bool" value="true"/>
                      <Option name="expression" type="QString" value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1500 THEN 2.5 &#xd;&#xa;WHEN @map_scale  > 1500 THEN 0&#xd;&#xa;END"/>
                      <Option name="type" type="int" value="3"/>
                    </Option>
                  </Option>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="1" type="line" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{125567a8-a047-460b-9af5-14ba91bb9a69}" class="SimpleLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="align_dash_pattern" type="QString" value="0"/>
            <Option name="capstyle" type="QString" value="square"/>
            <Option name="customdash" type="QString" value="5;2"/>
            <Option name="customdash_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="customdash_unit" type="QString" value="MM"/>
            <Option name="dash_pattern_offset" type="QString" value="0"/>
            <Option name="dash_pattern_offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="dash_pattern_offset_unit" type="QString" value="MM"/>
            <Option name="draw_inside_polygon" type="QString" value="0"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="line_color" type="QString" value="45,84,255,255,rgb:0.17647058823529413,0.32941176470588235,1,1"/>
            <Option name="line_style" type="QString" value="solid"/>
            <Option name="line_width" type="QString" value="0.36"/>
            <Option name="line_width_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="trim_distance_end" type="QString" value="0"/>
            <Option name="trim_distance_end_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_end_unit" type="QString" value="MM"/>
            <Option name="trim_distance_start" type="QString" value="0"/>
            <Option name="trim_distance_start_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_start_unit" type="QString" value="MM"/>
            <Option name="tweak_dash_pattern_on_corners" type="QString" value="0"/>
            <Option name="use_custom_dash" type="QString" value="0"/>
            <Option name="width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{7684a725-426f-47d3-859a-9e4bb0b9a024}" class="SimpleLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="align_dash_pattern" type="QString" value="0"/>
            <Option name="capstyle" type="QString" value="square"/>
            <Option name="customdash" type="QString" value="5;2"/>
            <Option name="customdash_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="customdash_unit" type="QString" value="MM"/>
            <Option name="dash_pattern_offset" type="QString" value="0"/>
            <Option name="dash_pattern_offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="dash_pattern_offset_unit" type="QString" value="MM"/>
            <Option name="draw_inside_polygon" type="QString" value="0"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="line_color" type="QString" value="219,219,219,0,hsv:0,0,0.86047150377660797,0"/>
            <Option name="line_style" type="QString" value="dot"/>
            <Option name="line_width" type="QString" value="0.3"/>
            <Option name="line_width_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="trim_distance_end" type="QString" value="0"/>
            <Option name="trim_distance_end_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_end_unit" type="QString" value="MM"/>
            <Option name="trim_distance_start" type="QString" value="0"/>
            <Option name="trim_distance_start_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_start_unit" type="QString" value="MM"/>
            <Option name="tweak_dash_pattern_on_corners" type="QString" value="0"/>
            <Option name="use_custom_dash" type="QString" value="0"/>
            <Option name="width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineColor" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when initoverflowpath = true then color_rgba(255,255,255,200) else color_rgba(100,100,100,0) end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.1 + 0.415 * ln((cat_geom1*cat_geom2) + 0.10)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.1 + 0.415 * ln((3.14*cat_geom1*cat_geom1/2) + 0.10)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{867127f5-d842-49bc-9fe7-f0c443d7eb32}" class="MarkerLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="average_angle_length" type="QString" value="4"/>
            <Option name="average_angle_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="average_angle_unit" type="QString" value="MM"/>
            <Option name="interval" type="QString" value="3"/>
            <Option name="interval_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="interval_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_along_line" type="QString" value="0"/>
            <Option name="offset_along_line_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_along_line_unit" type="QString" value="MM"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="place_on_every_part" type="bool" value="true"/>
            <Option name="placements" type="QString" value="CentralPoint"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="rotate" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" force_rhr="0" frame_rate="10" name="@1@2" type="marker" alpha="1" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="{8ffd9947-55a5-4c75-8756-c2fe1b12e838}" class="SimpleMarker" pass="0" enabled="1">
              <Option type="Map">
                <Option name="angle" type="QString" value="0"/>
                <Option name="cap_style" type="QString" value="square"/>
                <Option name="color" type="QString" value="45,84,255,255,rgb:0.17647058823529413,0.32941176470588235,1,1"/>
                <Option name="horizontal_anchor_point" type="QString" value="1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="name" type="QString" value="filled_arrowhead"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
                <Option name="outline_style" type="QString" value="solid"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="outline_width_unit" type="QString" value="MM"/>
                <Option name="scale_method" type="QString" value="diameter"/>
                <Option name="size" type="QString" value="2.56"/>
                <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="size_unit" type="QString" value="MM"/>
                <Option name="vertical_anchor_point" type="QString" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties" type="Map">
                    <Option name="size" type="Map">
                      <Option name="active" type="bool" value="true"/>
                      <Option name="expression" type="QString" value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1500 THEN 2.5 &#xd;&#xa;WHEN @map_scale  > 1500 THEN 0&#xd;&#xa;END"/>
                      <Option name="type" type="int" value="3"/>
                    </Option>
                  </Option>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="2" type="line" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{125567a8-a047-460b-9af5-14ba91bb9a69}" class="SimpleLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="align_dash_pattern" type="QString" value="0"/>
            <Option name="capstyle" type="QString" value="square"/>
            <Option name="customdash" type="QString" value="5;2"/>
            <Option name="customdash_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="customdash_unit" type="QString" value="MM"/>
            <Option name="dash_pattern_offset" type="QString" value="0"/>
            <Option name="dash_pattern_offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="dash_pattern_offset_unit" type="QString" value="MM"/>
            <Option name="draw_inside_polygon" type="QString" value="0"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="line_color" type="QString" value="245,128,26,255,rgb:0.96078431372549022,0.50196078431372548,0.10196078431372549,1"/>
            <Option name="line_style" type="QString" value="solid"/>
            <Option name="line_width" type="QString" value="0.36"/>
            <Option name="line_width_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="trim_distance_end" type="QString" value="0"/>
            <Option name="trim_distance_end_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_end_unit" type="QString" value="MM"/>
            <Option name="trim_distance_start" type="QString" value="0"/>
            <Option name="trim_distance_start_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_start_unit" type="QString" value="MM"/>
            <Option name="tweak_dash_pattern_on_corners" type="QString" value="0"/>
            <Option name="use_custom_dash" type="QString" value="0"/>
            <Option name="width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{867127f5-d842-49bc-9fe7-f0c443d7eb32}" class="MarkerLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="average_angle_length" type="QString" value="4"/>
            <Option name="average_angle_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="average_angle_unit" type="QString" value="MM"/>
            <Option name="interval" type="QString" value="3"/>
            <Option name="interval_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="interval_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_along_line" type="QString" value="0"/>
            <Option name="offset_along_line_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_along_line_unit" type="QString" value="MM"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="place_on_every_part" type="bool" value="true"/>
            <Option name="placements" type="QString" value="CentralPoint"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="rotate" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" force_rhr="0" frame_rate="10" name="@2@1" type="marker" alpha="1" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="{8ffd9947-55a5-4c75-8756-c2fe1b12e838}" class="SimpleMarker" pass="0" enabled="1">
              <Option type="Map">
                <Option name="angle" type="QString" value="0"/>
                <Option name="cap_style" type="QString" value="square"/>
                <Option name="color" type="QString" value="245,128,26,255,rgb:0.96078431372549022,0.50196078431372548,0.10196078431372549,1"/>
                <Option name="horizontal_anchor_point" type="QString" value="1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="name" type="QString" value="filled_arrowhead"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
                <Option name="outline_style" type="QString" value="solid"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="outline_width_unit" type="QString" value="MM"/>
                <Option name="scale_method" type="QString" value="diameter"/>
                <Option name="size" type="QString" value="2.56"/>
                <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="size_unit" type="QString" value="MM"/>
                <Option name="vertical_anchor_point" type="QString" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties" type="Map">
                    <Option name="size" type="Map">
                      <Option name="active" type="bool" value="true"/>
                      <Option name="expression" type="QString" value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1500 THEN 2.5 &#xd;&#xa;WHEN @map_scale  > 1500 THEN 0&#xd;&#xa;END"/>
                      <Option name="type" type="int" value="3"/>
                    </Option>
                  </Option>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="3" type="line" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{125567a8-a047-460b-9af5-14ba91bb9a69}" class="SimpleLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="align_dash_pattern" type="QString" value="0"/>
            <Option name="capstyle" type="QString" value="square"/>
            <Option name="customdash" type="QString" value="5;2"/>
            <Option name="customdash_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="customdash_unit" type="QString" value="MM"/>
            <Option name="dash_pattern_offset" type="QString" value="0"/>
            <Option name="dash_pattern_offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="dash_pattern_offset_unit" type="QString" value="MM"/>
            <Option name="draw_inside_polygon" type="QString" value="0"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="line_color" type="QString" value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1"/>
            <Option name="line_style" type="QString" value="dash"/>
            <Option name="line_width" type="QString" value="0.36"/>
            <Option name="line_width_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="trim_distance_end" type="QString" value="0"/>
            <Option name="trim_distance_end_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_end_unit" type="QString" value="MM"/>
            <Option name="trim_distance_start" type="QString" value="0"/>
            <Option name="trim_distance_start_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_start_unit" type="QString" value="MM"/>
            <Option name="tweak_dash_pattern_on_corners" type="QString" value="0"/>
            <Option name="use_custom_dash" type="QString" value="0"/>
            <Option name="width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{867127f5-d842-49bc-9fe7-f0c443d7eb32}" class="MarkerLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="average_angle_length" type="QString" value="4"/>
            <Option name="average_angle_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="average_angle_unit" type="QString" value="MM"/>
            <Option name="interval" type="QString" value="3"/>
            <Option name="interval_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="interval_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_along_line" type="QString" value="0"/>
            <Option name="offset_along_line_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_along_line_unit" type="QString" value="MM"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="place_on_every_part" type="bool" value="true"/>
            <Option name="placements" type="QString" value="CentralPoint"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="rotate" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="outlineWidth" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="case when cat_geom2 > 0.5 and cat_geom2 &lt;50 then&#xd;&#xa;0.378 + 0.715 * ln((cat_geom1*cat_geom2) + 0.720)&#xd;&#xa;when cat_geom1 is not null then&#xd;&#xa;0.378 + 0.715 * ln((3.14*cat_geom1*cat_geom1/2) + 0.720)&#xd;&#xa;else 0.35 end"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol is_animated="0" force_rhr="0" frame_rate="10" name="@3@1" type="marker" alpha="1" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="{8ffd9947-55a5-4c75-8756-c2fe1b12e838}" class="SimpleMarker" pass="0" enabled="1">
              <Option type="Map">
                <Option name="angle" type="QString" value="0"/>
                <Option name="cap_style" type="QString" value="square"/>
                <Option name="color" type="QString" value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1"/>
                <Option name="horizontal_anchor_point" type="QString" value="1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="name" type="QString" value="filled_arrowhead"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
                <Option name="outline_style" type="QString" value="solid"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="outline_width_unit" type="QString" value="MM"/>
                <Option name="scale_method" type="QString" value="diameter"/>
                <Option name="size" type="QString" value="2.56"/>
                <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="size_unit" type="QString" value="MM"/>
                <Option name="vertical_anchor_point" type="QString" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties" type="Map">
                    <Option name="size" type="Map">
                      <Option name="active" type="bool" value="true"/>
                      <Option name="expression" type="QString" value="CASE &#xd;&#xa;WHEN  @map_scale  &lt;= 1500 THEN 2.5 &#xd;&#xa;WHEN @map_scale  > 1500 THEN 0&#xd;&#xa;END"/>
                      <Option name="type" type="int" value="3"/>
                    </Option>
                  </Option>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="4" type="line" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{02aed3f9-a912-44fa-8432-84e6d86c257b}" class="SimpleLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="align_dash_pattern" type="QString" value="0"/>
            <Option name="capstyle" type="QString" value="round"/>
            <Option name="customdash" type="QString" value="5;2"/>
            <Option name="customdash_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="customdash_unit" type="QString" value="MM"/>
            <Option name="dash_pattern_offset" type="QString" value="0"/>
            <Option name="dash_pattern_offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="dash_pattern_offset_unit" type="QString" value="MM"/>
            <Option name="draw_inside_polygon" type="QString" value="0"/>
            <Option name="joinstyle" type="QString" value="round"/>
            <Option name="line_color" type="QString" value="85,95,105,255,hsv:0.58761111111111108,0.19267566948958573,0.41322957198443577,1"/>
            <Option name="line_style" type="QString" value="solid"/>
            <Option name="line_width" type="QString" value="0.35"/>
            <Option name="line_width_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="trim_distance_end" type="QString" value="0"/>
            <Option name="trim_distance_end_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_end_unit" type="QString" value="MM"/>
            <Option name="trim_distance_start" type="QString" value="0"/>
            <Option name="trim_distance_start_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_start_unit" type="QString" value="MM"/>
            <Option name="tweak_dash_pattern_on_corners" type="QString" value="0"/>
            <Option name="use_custom_dash" type="QString" value="0"/>
            <Option name="width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option name="name" type="QString" value=""/>
        <Option name="properties"/>
        <Option name="type" type="QString" value="collection"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="" type="line" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{3eade21d-240a-43fc-8947-ccec8cc9a73f}" class="SimpleLine" pass="0" enabled="1">
          <Option type="Map">
            <Option name="align_dash_pattern" type="QString" value="0"/>
            <Option name="capstyle" type="QString" value="square"/>
            <Option name="customdash" type="QString" value="5;2"/>
            <Option name="customdash_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="customdash_unit" type="QString" value="MM"/>
            <Option name="dash_pattern_offset" type="QString" value="0"/>
            <Option name="dash_pattern_offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="dash_pattern_offset_unit" type="QString" value="MM"/>
            <Option name="draw_inside_polygon" type="QString" value="0"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="line_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
            <Option name="line_style" type="QString" value="solid"/>
            <Option name="line_width" type="QString" value="0.26"/>
            <Option name="line_width_unit" type="QString" value="MM"/>
            <Option name="offset" type="QString" value="0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="ring_filter" type="QString" value="0"/>
            <Option name="trim_distance_end" type="QString" value="0"/>
            <Option name="trim_distance_end_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_end_unit" type="QString" value="MM"/>
            <Option name="trim_distance_start" type="QString" value="0"/>
            <Option name="trim_distance_start_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="trim_distance_start_unit" type="QString" value="MM"/>
            <Option name="tweak_dash_pattern_on_corners" type="QString" value="0"/>
            <Option name="use_custom_dash" type="QString" value="0"/>
            <Option name="width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>1</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('110', 've_connec', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis labelsEnabled="1" version="3.40.8-Bratislava" styleCategories="Symbology|Labeling">
  <renderer-v2 symbollevels="0" type="RuleRenderer" referencescale="-1" enableorderby="0" forceraster="0">
    <rules key="{cd75f41e-3b1d-443c-8148-fbc4436aa9cb}">
      <rule key="{abcdb374-fe6a-4d04-a466-31fdd93144e8}" label="Planned obsolete gully" filter="state = 1 and (p_state &lt;> 0 or p_state is null)" symbol="0" scalemaxdenom="1500"/>
      <rule key="{5ed6d5c8-0054-42c1-a268-53e042760284}" label="OBSOLETE" filter="state=0" symbol="1" scalemaxdenom="1500"/>
      <rule key="{deedf78b-1b14-4314-b775-536678965a4f}" label="PLANIFIED" filter="state=2" symbol="2" scalemaxdenom="1500"/>
      <rule key="{b0e34206-b0d8-424d-a80a-21fec3287f94}" label="PHASE-OUT" filter="state=1 AND p_state=0" symbol="3" scalemaxdenom="1500"/>
      <rule key="{fcb93b3a-1412-448e-b95f-627bfe328230}" label="(drawing)" filter="ELSE" symbol="4"/>
    </rules>
    <symbols>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="0" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{362f8968-f888-433b-90e4-e5098d869499}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="49,180,227,255,rgb:0.19215686274509805,0.70588235294117652,0.8901960784313725,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="49,180,227,255,rgb:0.19215686274509805,0.70588235294117652,0.8901960784313725,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 3.5, 2, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{67948e1f-e6bb-4593-b5ad-8bb9fcf49d7d}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="cross"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="2"/>
                      <Option name="maxValue" type="double" value="1500"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="1" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="120,120,120,153,hsv:0.56711111111111112,0,0.4690928511482414,0.59999999999999998"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="120,120,120,153,hsv:0.56711111111111112,0,0.4690928511482414,0.59999999999999998"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="2" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="245,128,26,255,rgb:0.96078431372549022,0.50196078431372548,0.10196078431372549,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="208,100,6,255,hsv:0.07763888888888888,0.97120622568093384,0.81702906843671319,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="3" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="61,180,244,255,hsv:0.55844444444444441,0.74923323414969101,0.95664911879148551,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="4" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{08733df3-bc13-4eac-bf5c-58b353a68ba7}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="85,95,105,255,hsv:0.58761111111111108,0.19267566948958573,0.41322957198443577,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.6"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option name="name" type="QString" value=""/>
        <Option name="properties"/>
        <Option name="type" type="QString" value="collection"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{593cbcfc-245e-4774-ad13-56169b965bf5}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style legendString="Aa" textOpacity="1" multilineHeight="1" forcedItalic="0" previewBkgrdColor="255,255,255,255,rgb:1,1,1,1" fontStrikeout="0" textOrientation="horizontal" multilineHeightUnit="Percentage" tabStopDistanceUnit="Point" capitalization="0" textColor="50,50,50,255,rgb:0.19607843137254902,0.19607843137254902,0.19607843137254902,1" blendMode="0" tabStopDistance="80" fontSizeMapUnitScale="3x:0,0,0,0,0,0" fontSize="8" forcedBold="0" fieldName="arc_id" fontWordSpacing="0" fontFamily="Arial" useSubstitutions="0" fontUnderline="0" fontSizeUnit="Point" tabStopDistanceMapUnitScale="3x:0,0,0,0,0,0" isExpression="0" fontWeight="50" fontKerning="1" stretchFactor="100" allowHtml="0" fontLetterSpacing="0" namedStyle="Normal" fontItalic="0">
        <families/>
        <text-buffer bufferJoinStyle="128" bufferNoFill="1" bufferSize="1" bufferDraw="0" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferColor="250,250,250,255,rgb:0.98039215686274506,0.98039215686274506,0.98039215686274506,1" bufferSizeUnits="MM" bufferOpacity="1" bufferBlendMode="0"/>
        <text-mask maskType="0" maskSizeUnits="MM" maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskOpacity="1" maskSize2="1.5" maskedSymbolLayers="" maskJoinStyle="128" maskEnabled="0" maskSize="1.5"/>
        <background shapeSizeX="0" shapeOffsetUnit="Point" shapeType="0" shapeDraw="0" shapeBorderWidth="0" shapeRotationType="0" shapeJoinStyle="64" shapeSizeType="0" shapeOffsetX="0" shapeSizeUnit="Point" shapeBlendMode="0" shapeRadiiY="0" shapeSVGFile="" shapeBorderColor="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1" shapeRadiiUnit="Point" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeRotation="0" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeOpacity="1" shapeRadiiX="0" shapeFillColor="255,255,255,255,rgb:1,1,1,1" shapeOffsetY="0" shapeSizeY="0" shapeBorderWidthUnit="Point">
          <symbol is_animated="0" force_rhr="0" frame_rate="10" name="markerSymbol" type="marker" alpha="1" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="" class="SimpleMarker" pass="0" enabled="1">
              <Option type="Map">
                <Option name="angle" type="QString" value="0"/>
                <Option name="cap_style" type="QString" value="square"/>
                <Option name="color" type="QString" value="213,180,60,255,rgb:0.83529411764705885,0.70588235294117652,0.23529411764705882,1"/>
                <Option name="horizontal_anchor_point" type="QString" value="1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="name" type="QString" value="circle"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
                <Option name="outline_style" type="QString" value="solid"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="outline_width_unit" type="QString" value="MM"/>
                <Option name="scale_method" type="QString" value="diameter"/>
                <Option name="size" type="QString" value="2"/>
                <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="size_unit" type="QString" value="MM"/>
                <Option name="vertical_anchor_point" type="QString" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties"/>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
          <symbol is_animated="0" force_rhr="0" frame_rate="10" name="fillSymbol" type="fill" alpha="1" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="" class="SimpleFill" pass="0" enabled="1">
              <Option type="Map">
                <Option name="border_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1"/>
                <Option name="outline_style" type="QString" value="no"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_unit" type="QString" value="Point"/>
                <Option name="style" type="QString" value="solid"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties"/>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </background>
        <shadow shadowUnder="0" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowColor="0,0,0,255,rgb:0,0,0,1" shadowScale="100" shadowDraw="0" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowOffsetAngle="135" shadowOffsetUnit="MM" shadowOffsetDist="1" shadowBlendMode="6" shadowOffsetGlobal="1" shadowRadius="1.5" shadowRadiusAlphaOnly="0" shadowRadiusUnit="MM" shadowOpacity="0.69999999999999996"/>
        <dd_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </dd_properties>
        <substitutions/>
      </text-style>
      <text-format multilineAlign="3" addDirectionSymbol="0" plussign="0" rightDirectionSymbol=">" decimals="3" useMaxLineLengthForAutoWrap="1" formatNumbers="0" autoWrapLength="0" wrapChar="" leftDirectionSymbol="&lt;" reverseDirectionSymbol="0" placeDirectionSymbol="0"/>
      <placement overrunDistance="0" offsetUnits="MM" distUnits="MM" lineAnchorPercent="0.5" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" rotationAngle="0" polygonPlacementFlags="2" offsetType="1" xOffset="0" overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" geometryGeneratorType="PointGeometry" lineAnchorTextPoint="FollowPlacement" dist="0" prioritization="PreferCloser" maximumDistance="0" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" repeatDistance="0" maxCurvedCharAngleIn="25" overlapHandling="PreventOverlap" centroidInside="0" maximumDistanceMapUnitScale="3x:0,0,0,0,0,0" quadOffset="4" preserveRotation="1" placementFlags="10" centroidWhole="0" lineAnchorType="0" rotationUnit="AngleDegrees" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" maximumDistanceUnit="MM" priority="5" geometryGenerator="" maxCurvedCharAngleOut="-25" overrunDistanceUnit="MM" lineAnchorClipping="0" distMapUnitScale="3x:0,0,0,0,0,0" fitInPolygonOnly="0" layerType="PointGeometry" repeatDistanceUnits="MM" placement="6" yOffset="0" geometryGeneratorEnabled="0" allowDegraded="0"/>
      <rendering maxNumLabels="2000" zIndex="0" scaleMax="500" scaleMin="0" minFeatureSize="0" obstacle="1" scaleVisibility="1" drawLabels="1" obstacleFactor="1" upsidedownLabels="0" fontLimitPixelSize="0" mergeLines="0" limitNumLabels="0" labelPerPart="0" obstacleType="1" fontMinPixelSize="3" unplacedVisibility="0" fontMaxPixelSize="10000"/>
      <dd_properties>
        <Option type="Map">
          <Option name="name" type="QString" value=""/>
          <Option name="properties"/>
          <Option name="type" type="QString" value="collection"/>
        </Option>
      </dd_properties>
      <callout type="simple">
        <Option type="Map">
          <Option name="anchorPoint" type="QString" value="pole_of_inaccessibility"/>
          <Option name="blendMode" type="int" value="0"/>
          <Option name="ddProperties" type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
          <Option name="drawToAllParts" type="bool" value="false"/>
          <Option name="enabled" type="QString" value="0"/>
          <Option name="labelAnchorPoint" type="QString" value="point_on_exterior"/>
          <Option name="lineSymbol" type="QString" value="&lt;symbol is_animated=&quot;0&quot; force_rhr=&quot;0&quot; frame_rate=&quot;10&quot; name=&quot;symbol&quot; type=&quot;line&quot; alpha=&quot;1&quot; clip_to_extent=&quot;1&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;name&quot; type=&quot;QString&quot; value=&quot;&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option name=&quot;type&quot; type=&quot;QString&quot; value=&quot;collection&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer locked=&quot;0&quot; id=&quot;{8b192846-a06f-4f5a-bc59-5574a887e5a5}&quot; class=&quot;SimpleLine&quot; pass=&quot;0&quot; enabled=&quot;1&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;align_dash_pattern&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;capstyle&quot; type=&quot;QString&quot; value=&quot;square&quot;/>&lt;Option name=&quot;customdash&quot; type=&quot;QString&quot; value=&quot;5;2&quot;/>&lt;Option name=&quot;customdash_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;customdash_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;dash_pattern_offset&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;dash_pattern_offset_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;dash_pattern_offset_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;draw_inside_polygon&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;joinstyle&quot; type=&quot;QString&quot; value=&quot;bevel&quot;/>&lt;Option name=&quot;line_color&quot; type=&quot;QString&quot; value=&quot;60,60,60,255,rgb:0.23529411764705882,0.23529411764705882,0.23529411764705882,1&quot;/>&lt;Option name=&quot;line_style&quot; type=&quot;QString&quot; value=&quot;solid&quot;/>&lt;Option name=&quot;line_width&quot; type=&quot;QString&quot; value=&quot;0.3&quot;/>&lt;Option name=&quot;line_width_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;offset&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;offset_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;offset_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;ring_filter&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_end&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_end_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;trim_distance_end_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;trim_distance_start&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_start_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;trim_distance_start_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;tweak_dash_pattern_on_corners&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;use_custom_dash&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;width_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;name&quot; type=&quot;QString&quot; value=&quot;&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option name=&quot;type&quot; type=&quot;QString&quot; value=&quot;collection&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>"/>
          <Option name="minLength" type="double" value="0"/>
          <Option name="minLengthMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="minLengthUnit" type="QString" value="MM"/>
          <Option name="offsetFromAnchor" type="double" value="0"/>
          <Option name="offsetFromAnchorMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="offsetFromAnchorUnit" type="QString" value="MM"/>
          <Option name="offsetFromLabel" type="double" value="0"/>
          <Option name="offsetFromLabelMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="offsetFromLabelUnit" type="QString" value="MM"/>
        </Option>
      </callout>
    </settings>
  </labeling>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('110', 've_gully', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis labelsEnabled="1" version="3.40.8-Bratislava" styleCategories="Symbology|Labeling">
  <renderer-v2 symbollevels="0" type="RuleRenderer" referencescale="-1" enableorderby="0" forceraster="0">
    <rules key="{cd75f41e-3b1d-443c-8148-fbc4436aa9cb}">
      <rule key="{abcdb374-fe6a-4d04-a466-31fdd93144e8}" label="Planned obsolete gully" filter="state = 1 and (p_state &lt;> 0 or p_state is null)" symbol="0" scalemaxdenom="1500"/>
      <rule key="{5ed6d5c8-0054-42c1-a268-53e042760284}" label="OBSOLETE" filter="state=0" symbol="1" scalemaxdenom="1500"/>
      <rule key="{deedf78b-1b14-4314-b775-536678965a4f}" label="PLANIFIED" filter="state=2" symbol="2" scalemaxdenom="1500"/>
      <rule key="{b0e34206-b0d8-424d-a80a-21fec3287f94}" label="PHASE-OUT" filter="state=1 AND p_state=0" symbol="3" scalemaxdenom="1500"/>
      <rule key="{fcb93b3a-1412-448e-b95f-627bfe328230}" label="(drawing)" filter="ELSE" symbol="4"/>
    </rules>
    <symbols>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="0" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{362f8968-f888-433b-90e4-e5098d869499}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="angle" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="field" type="QString" value="rotation"/>
                  <Option name="type" type="int" value="2"/>
                </Option>
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_exp(var(''map_scale''), 0, 1500, 3.5, 2, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="1" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="120,120,120,153,hsv:0.56711111111111112,0,0.4690928511482414,0.59999999999999998"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="120,120,120,153,hsv:0.56711111111111112,0,0.4690928511482414,0.59999999999999998"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="2" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="245,128,26,255,rgb:0.96078431372549022,0.50196078431372548,0.10196078431372549,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="208,100,6,255,hsv:0.07763888888888888,0.97120622568093384,0.81702906843671319,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="3" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{c3168ec5-08d4-4f23-95b2-b9080a65290a}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="61,180,244,255,hsv:0.55844444444444441,0.74923323414969101,0.95664911879148551,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.8"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.52"/>
                      <Option name="maxSize" type="double" value="1"/>
                      <Option name="maxValue" type="double" value="5000"/>
                      <Option name="minSize" type="double" value="2"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="4" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{08733df3-bc13-4eac-bf5c-58b353a68ba7}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="85,95,105,255,hsv:0.58761111111111108,0.19267566948958573,0.41322957198443577,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.6"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option name="name" type="QString" value=""/>
        <Option name="properties"/>
        <Option name="type" type="QString" value="collection"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{593cbcfc-245e-4774-ad13-56169b965bf5}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style legendString="Aa" textOpacity="1" multilineHeight="1" forcedItalic="0" previewBkgrdColor="255,255,255,255,rgb:1,1,1,1" fontStrikeout="0" textOrientation="horizontal" multilineHeightUnit="Percentage" tabStopDistanceUnit="Point" capitalization="0" textColor="50,50,50,255,rgb:0.19607843137254902,0.19607843137254902,0.19607843137254902,1" blendMode="0" tabStopDistance="80" fontSizeMapUnitScale="3x:0,0,0,0,0,0" fontSize="8" forcedBold="0" fieldName="arc_id" fontWordSpacing="0" fontFamily="Arial" useSubstitutions="0" fontUnderline="0" fontSizeUnit="Point" tabStopDistanceMapUnitScale="3x:0,0,0,0,0,0" isExpression="0" fontWeight="50" fontKerning="1" stretchFactor="100" allowHtml="0" fontLetterSpacing="0" namedStyle="Normal" fontItalic="0">
        <families/>
        <text-buffer bufferJoinStyle="128" bufferNoFill="1" bufferSize="1" bufferDraw="0" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferColor="250,250,250,255,rgb:0.98039215686274506,0.98039215686274506,0.98039215686274506,1" bufferSizeUnits="MM" bufferOpacity="1" bufferBlendMode="0"/>
        <text-mask maskType="0" maskSizeUnits="MM" maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskOpacity="1" maskSize2="1.5" maskedSymbolLayers="" maskJoinStyle="128" maskEnabled="0" maskSize="1.5"/>
        <background shapeSizeX="0" shapeOffsetUnit="Point" shapeType="0" shapeDraw="0" shapeBorderWidth="0" shapeRotationType="0" shapeJoinStyle="64" shapeSizeType="0" shapeOffsetX="0" shapeSizeUnit="Point" shapeBlendMode="0" shapeRadiiY="0" shapeSVGFile="" shapeBorderColor="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1" shapeRadiiUnit="Point" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeRotation="0" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeOpacity="1" shapeRadiiX="0" shapeFillColor="255,255,255,255,rgb:1,1,1,1" shapeOffsetY="0" shapeSizeY="0" shapeBorderWidthUnit="Point">
          <symbol is_animated="0" force_rhr="0" frame_rate="10" name="markerSymbol" type="marker" alpha="1" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="" class="SimpleMarker" pass="0" enabled="1">
              <Option type="Map">
                <Option name="angle" type="QString" value="0"/>
                <Option name="cap_style" type="QString" value="square"/>
                <Option name="color" type="QString" value="213,180,60,255,rgb:0.83529411764705885,0.70588235294117652,0.23529411764705882,1"/>
                <Option name="horizontal_anchor_point" type="QString" value="1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="name" type="QString" value="circle"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
                <Option name="outline_style" type="QString" value="solid"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="outline_width_unit" type="QString" value="MM"/>
                <Option name="scale_method" type="QString" value="diameter"/>
                <Option name="size" type="QString" value="2"/>
                <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="size_unit" type="QString" value="MM"/>
                <Option name="vertical_anchor_point" type="QString" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties"/>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
          <symbol is_animated="0" force_rhr="0" frame_rate="10" name="fillSymbol" type="fill" alpha="1" clip_to_extent="1">
            <data_defined_properties>
              <Option type="Map">
                <Option name="name" type="QString" value=""/>
                <Option name="properties"/>
                <Option name="type" type="QString" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer locked="0" id="" class="SimpleFill" pass="0" enabled="1">
              <Option type="Map">
                <Option name="border_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
                <Option name="joinstyle" type="QString" value="bevel"/>
                <Option name="offset" type="QString" value="0,0"/>
                <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
                <Option name="offset_unit" type="QString" value="MM"/>
                <Option name="outline_color" type="QString" value="128,128,128,255,rgb:0.50196078431372548,0.50196078431372548,0.50196078431372548,1"/>
                <Option name="outline_style" type="QString" value="no"/>
                <Option name="outline_width" type="QString" value="0"/>
                <Option name="outline_width_unit" type="QString" value="Point"/>
                <Option name="style" type="QString" value="solid"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option name="name" type="QString" value=""/>
                  <Option name="properties"/>
                  <Option name="type" type="QString" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </background>
        <shadow shadowUnder="0" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0" shadowColor="0,0,0,255,rgb:0,0,0,1" shadowScale="100" shadowDraw="0" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowOffsetAngle="135" shadowOffsetUnit="MM" shadowOffsetDist="1" shadowBlendMode="6" shadowOffsetGlobal="1" shadowRadius="1.5" shadowRadiusAlphaOnly="0" shadowRadiusUnit="MM" shadowOpacity="0.69999999999999996"/>
        <dd_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </dd_properties>
        <substitutions/>
      </text-style>
      <text-format multilineAlign="3" addDirectionSymbol="0" plussign="0" rightDirectionSymbol=">" decimals="3" useMaxLineLengthForAutoWrap="1" formatNumbers="0" autoWrapLength="0" wrapChar="" leftDirectionSymbol="&lt;" reverseDirectionSymbol="0" placeDirectionSymbol="0"/>
      <placement overrunDistance="0" offsetUnits="MM" distUnits="MM" lineAnchorPercent="0.5" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" rotationAngle="0" polygonPlacementFlags="2" offsetType="1" xOffset="0" overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" geometryGeneratorType="PointGeometry" lineAnchorTextPoint="FollowPlacement" dist="0" prioritization="PreferCloser" maximumDistance="0" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" repeatDistance="0" maxCurvedCharAngleIn="25" overlapHandling="PreventOverlap" centroidInside="0" maximumDistanceMapUnitScale="3x:0,0,0,0,0,0" quadOffset="4" preserveRotation="1" placementFlags="10" centroidWhole="0" lineAnchorType="0" rotationUnit="AngleDegrees" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" maximumDistanceUnit="MM" priority="5" geometryGenerator="" maxCurvedCharAngleOut="-25" overrunDistanceUnit="MM" lineAnchorClipping="0" distMapUnitScale="3x:0,0,0,0,0,0" fitInPolygonOnly="0" layerType="PointGeometry" repeatDistanceUnits="MM" placement="6" yOffset="0" geometryGeneratorEnabled="0" allowDegraded="0"/>
      <rendering maxNumLabels="2000" zIndex="0" scaleMax="500" scaleMin="0" minFeatureSize="0" obstacle="1" scaleVisibility="1" drawLabels="1" obstacleFactor="1" upsidedownLabels="0" fontLimitPixelSize="0" mergeLines="0" limitNumLabels="0" labelPerPart="0" obstacleType="1" fontMinPixelSize="3" unplacedVisibility="0" fontMaxPixelSize="10000"/>
      <dd_properties>
        <Option type="Map">
          <Option name="name" type="QString" value=""/>
          <Option name="properties"/>
          <Option name="type" type="QString" value="collection"/>
        </Option>
      </dd_properties>
      <callout type="simple">
        <Option type="Map">
          <Option name="anchorPoint" type="QString" value="pole_of_inaccessibility"/>
          <Option name="blendMode" type="int" value="0"/>
          <Option name="ddProperties" type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
          <Option name="drawToAllParts" type="bool" value="false"/>
          <Option name="enabled" type="QString" value="0"/>
          <Option name="labelAnchorPoint" type="QString" value="point_on_exterior"/>
          <Option name="lineSymbol" type="QString" value="&lt;symbol is_animated=&quot;0&quot; force_rhr=&quot;0&quot; frame_rate=&quot;10&quot; name=&quot;symbol&quot; type=&quot;line&quot; alpha=&quot;1&quot; clip_to_extent=&quot;1&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;name&quot; type=&quot;QString&quot; value=&quot;&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option name=&quot;type&quot; type=&quot;QString&quot; value=&quot;collection&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer locked=&quot;0&quot; id=&quot;{8b192846-a06f-4f5a-bc59-5574a887e5a5}&quot; class=&quot;SimpleLine&quot; pass=&quot;0&quot; enabled=&quot;1&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;align_dash_pattern&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;capstyle&quot; type=&quot;QString&quot; value=&quot;square&quot;/>&lt;Option name=&quot;customdash&quot; type=&quot;QString&quot; value=&quot;5;2&quot;/>&lt;Option name=&quot;customdash_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;customdash_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;dash_pattern_offset&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;dash_pattern_offset_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;dash_pattern_offset_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;draw_inside_polygon&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;joinstyle&quot; type=&quot;QString&quot; value=&quot;bevel&quot;/>&lt;Option name=&quot;line_color&quot; type=&quot;QString&quot; value=&quot;60,60,60,255,rgb:0.23529411764705882,0.23529411764705882,0.23529411764705882,1&quot;/>&lt;Option name=&quot;line_style&quot; type=&quot;QString&quot; value=&quot;solid&quot;/>&lt;Option name=&quot;line_width&quot; type=&quot;QString&quot; value=&quot;0.3&quot;/>&lt;Option name=&quot;line_width_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;offset&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;offset_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;offset_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;ring_filter&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_end&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_end_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;trim_distance_end_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;trim_distance_start&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;trim_distance_start_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;Option name=&quot;trim_distance_start_unit&quot; type=&quot;QString&quot; value=&quot;MM&quot;/>&lt;Option name=&quot;tweak_dash_pattern_on_corners&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;use_custom_dash&quot; type=&quot;QString&quot; value=&quot;0&quot;/>&lt;Option name=&quot;width_map_unit_scale&quot; type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option name=&quot;name&quot; type=&quot;QString&quot; value=&quot;&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option name=&quot;type&quot; type=&quot;QString&quot; value=&quot;collection&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>"/>
          <Option name="minLength" type="double" value="0"/>
          <Option name="minLengthMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="minLengthUnit" type="QString" value="MM"/>
          <Option name="offsetFromAnchor" type="double" value="0"/>
          <Option name="offsetFromAnchorMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="offsetFromAnchorUnit" type="QString" value="MM"/>
          <Option name="offsetFromLabel" type="double" value="0"/>
          <Option name="offsetFromLabelMapUnitScale" type="QString" value="3x:0,0,0,0,0,0"/>
          <Option name="offsetFromLabelUnit" type="QString" value="MM"/>
        </Option>
      </callout>
    </settings>
  </labeling>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('110', 've_link', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis styleCategories="Symbology|Labeling" labelsEnabled="0" version="3.40.8-Bratislava">
  <renderer-v2 type="RuleRenderer" symbollevels="0" enableorderby="0" forceraster="0" referencescale="-1">
    <rules key="{3627fdbf-9032-4f99-98f5-987f42c1d2e0}">
      <rule scalemaxdenom="1500" key="{c7c3ad4f-2e17-412d-b470-f74b0fb90dd7}" symbol="0" label="OBSOLETE" filter="&quot;state&quot; = 0"/>
      <rule scalemaxdenom="1500" key="{4bd523e5-f539-47ee-8657-8dd5ff0ff1a0}" symbol="1" label="OPERATIVE" filter="&quot;state&quot; = 1 and (p_state &lt;> 0 or p_state is null)"/>
      <rule scalemaxdenom="1500" key="{01c170bf-fd77-439a-8a4c-77f81317d68d}" symbol="2" label="PLANIFIED" filter="&quot;state&quot; = 2"/>
      <rule scalemaxdenom="1500" key="{6ee023a4-d351-435f-9f0e-473416f81281}" symbol="3" label="PHASE-OUT" filter="state = 1 and p_state = 0"/>
      <rule key="{9efb541a-c518-4c89-a85f-e2f7df3ab6dd}" symbol="4" label="(drawing)" filter="ELSE"/>
    </rules>
    <symbols>
      <symbol type="line" name="0" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" id="{b2bcf51a-bdc4-4f2c-abb3-40c1d6352215}" locked="0" pass="0" class="SimpleLine">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="162,162,162,255,rgb:0.63529411764705879,0.63529411764705879,0.63529411764705879,1"/>
            <Option type="QString" name="line_style" value="dot"/>
            <Option type="QString" name="line_width" value="0.3"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer enabled="1" id="{f8a0a105-a7fd-4afc-9ef9-5ce95d651012}" locked="0" pass="0" class="GeometryGenerator">
          <Option type="Map">
            <Option type="QString" name="SymbolType" value="Marker"/>
            <Option type="QString" name="geometryModifier" value="end_point ($geometry)"/>
            <Option type="QString" name="units" value="MapUnit"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol type="marker" name="@0@1" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" name="name" value=""/>
                <Option name="properties"/>
                <Option type="QString" name="type" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer enabled="1" id="{b21d7a97-025f-478e-9381-cb8cabb2ac7a}" locked="0" pass="0" class="SimpleMarker">
              <Option type="Map">
                <Option type="QString" name="angle" value="0"/>
                <Option type="QString" name="cap_style" value="square"/>
                <Option type="QString" name="color" value="255,0,0,255,rgb:1,0,0,1"/>
                <Option type="QString" name="horizontal_anchor_point" value="1"/>
                <Option type="QString" name="joinstyle" value="bevel"/>
                <Option type="QString" name="name" value="cross2"/>
                <Option type="QString" name="offset" value="0,0"/>
                <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="offset_unit" value="MM"/>
                <Option type="QString" name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
                <Option type="QString" name="outline_style" value="solid"/>
                <Option type="QString" name="outline_width" value="0"/>
                <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="outline_width_unit" value="MM"/>
                <Option type="QString" name="scale_method" value="diameter"/>
                <Option type="QString" name="size" value="1.8"/>
                <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="size_unit" value="MM"/>
                <Option type="QString" name="vertical_anchor_point" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" name="name" value=""/>
                  <Option name="properties"/>
                  <Option type="QString" name="type" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol type="line" name="1" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" id="{b2bcf51a-bdc4-4f2c-abb3-40c1d6352215}" locked="0" pass="0" class="SimpleLine">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="253,0,93,255,rgb:0.99215686274509807,0,0.36470588235294116,1"/>
            <Option type="QString" name="line_style" value="dot"/>
            <Option type="QString" name="line_width" value="0.25"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer enabled="1" id="{f8a0a105-a7fd-4afc-9ef9-5ce95d651012}" locked="0" pass="0" class="GeometryGenerator">
          <Option type="Map">
            <Option type="QString" name="SymbolType" value="Marker"/>
            <Option type="QString" name="geometryModifier" value="end_point ($geometry)"/>
            <Option type="QString" name="units" value="MapUnit"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol type="marker" name="@1@1" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" name="name" value=""/>
                <Option name="properties"/>
                <Option type="QString" name="type" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer enabled="1" id="{b21d7a97-025f-478e-9381-cb8cabb2ac7a}" locked="0" pass="0" class="SimpleMarker">
              <Option type="Map">
                <Option type="QString" name="angle" value="0"/>
                <Option type="QString" name="cap_style" value="square"/>
                <Option type="QString" name="color" value="255,0,0,255,rgb:1,0,0,1"/>
                <Option type="QString" name="horizontal_anchor_point" value="1"/>
                <Option type="QString" name="joinstyle" value="bevel"/>
                <Option type="QString" name="name" value="cross2"/>
                <Option type="QString" name="offset" value="0,0"/>
                <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="offset_unit" value="MM"/>
                <Option type="QString" name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
                <Option type="QString" name="outline_style" value="solid"/>
                <Option type="QString" name="outline_width" value="0"/>
                <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="outline_width_unit" value="MM"/>
                <Option type="QString" name="scale_method" value="diameter"/>
                <Option type="QString" name="size" value="1.8"/>
                <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="size_unit" value="MM"/>
                <Option type="QString" name="vertical_anchor_point" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" name="name" value=""/>
                  <Option name="properties"/>
                  <Option type="QString" name="type" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol type="line" name="2" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" id="{b2bcf51a-bdc4-4f2c-abb3-40c1d6352215}" locked="0" pass="0" class="SimpleLine">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="245,186,26,255,hsv:0.12205555555555556,0.89387350270847643,0.96078431372549022,1"/>
            <Option type="QString" name="line_style" value="dot"/>
            <Option type="QString" name="line_width" value="0.3"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer enabled="1" id="{f8a0a105-a7fd-4afc-9ef9-5ce95d651012}" locked="0" pass="0" class="GeometryGenerator">
          <Option type="Map">
            <Option type="QString" name="SymbolType" value="Marker"/>
            <Option type="QString" name="geometryModifier" value="end_point ($geometry)"/>
            <Option type="QString" name="units" value="MapUnit"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol type="marker" name="@2@1" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" name="name" value=""/>
                <Option name="properties"/>
                <Option type="QString" name="type" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer enabled="1" id="{b21d7a97-025f-478e-9381-cb8cabb2ac7a}" locked="0" pass="0" class="SimpleMarker">
              <Option type="Map">
                <Option type="QString" name="angle" value="0"/>
                <Option type="QString" name="cap_style" value="square"/>
                <Option type="QString" name="color" value="255,0,0,255,rgb:1,0,0,1"/>
                <Option type="QString" name="horizontal_anchor_point" value="1"/>
                <Option type="QString" name="joinstyle" value="bevel"/>
                <Option type="QString" name="name" value="cross2"/>
                <Option type="QString" name="offset" value="0,0"/>
                <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="offset_unit" value="MM"/>
                <Option type="QString" name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
                <Option type="QString" name="outline_style" value="solid"/>
                <Option type="QString" name="outline_width" value="0"/>
                <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="outline_width_unit" value="MM"/>
                <Option type="QString" name="scale_method" value="diameter"/>
                <Option type="QString" name="size" value="1.8"/>
                <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="size_unit" value="MM"/>
                <Option type="QString" name="vertical_anchor_point" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" name="name" value=""/>
                  <Option name="properties"/>
                  <Option type="QString" name="type" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol type="line" name="3" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" id="{b2bcf51a-bdc4-4f2c-abb3-40c1d6352215}" locked="0" pass="0" class="SimpleLine">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="186,231,255,255,hsv:0.55844444444444441,0.27228198672465093,1,1"/>
            <Option type="QString" name="line_style" value="dot"/>
            <Option type="QString" name="line_width" value="0.3"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer enabled="1" id="{f8a0a105-a7fd-4afc-9ef9-5ce95d651012}" locked="0" pass="0" class="GeometryGenerator">
          <Option type="Map">
            <Option type="QString" name="SymbolType" value="Marker"/>
            <Option type="QString" name="geometryModifier" value="end_point ($geometry)"/>
            <Option type="QString" name="units" value="MapUnit"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol type="marker" name="@3@1" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" name="name" value=""/>
                <Option name="properties"/>
                <Option type="QString" name="type" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer enabled="1" id="{b21d7a97-025f-478e-9381-cb8cabb2ac7a}" locked="0" pass="0" class="SimpleMarker">
              <Option type="Map">
                <Option type="QString" name="angle" value="0"/>
                <Option type="QString" name="cap_style" value="square"/>
                <Option type="QString" name="color" value="255,0,0,255,rgb:1,0,0,1"/>
                <Option type="QString" name="horizontal_anchor_point" value="1"/>
                <Option type="QString" name="joinstyle" value="bevel"/>
                <Option type="QString" name="name" value="cross2"/>
                <Option type="QString" name="offset" value="0,0"/>
                <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="offset_unit" value="MM"/>
                <Option type="QString" name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
                <Option type="QString" name="outline_style" value="solid"/>
                <Option type="QString" name="outline_width" value="0"/>
                <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="outline_width_unit" value="MM"/>
                <Option type="QString" name="scale_method" value="diameter"/>
                <Option type="QString" name="size" value="1.8"/>
                <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="size_unit" value="MM"/>
                <Option type="QString" name="vertical_anchor_point" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" name="name" value=""/>
                  <Option name="properties"/>
                  <Option type="QString" name="type" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
      <symbol type="line" name="4" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" id="{b2bcf51a-bdc4-4f2c-abb3-40c1d6352215}" locked="0" pass="0" class="SimpleLine">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="85,95,105,255,rgb:0.33333333333333331,0.37254901960784315,0.41176470588235292,1"/>
            <Option type="QString" name="line_style" value="dot"/>
            <Option type="QString" name="line_width" value="0.3"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer enabled="1" id="{f8a0a105-a7fd-4afc-9ef9-5ce95d651012}" locked="0" pass="0" class="GeometryGenerator">
          <Option type="Map">
            <Option type="QString" name="SymbolType" value="Marker"/>
            <Option type="QString" name="geometryModifier" value="end_point ($geometry)"/>
            <Option type="QString" name="units" value="MapUnit"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
          <symbol type="marker" name="@4@1" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" name="name" value=""/>
                <Option name="properties"/>
                <Option type="QString" name="type" value="collection"/>
              </Option>
            </data_defined_properties>
            <layer enabled="1" id="{b21d7a97-025f-478e-9381-cb8cabb2ac7a}" locked="0" pass="0" class="SimpleMarker">
              <Option type="Map">
                <Option type="QString" name="angle" value="0"/>
                <Option type="QString" name="cap_style" value="square"/>
                <Option type="QString" name="color" value="255,0,0,255,rgb:1,0,0,1"/>
                <Option type="QString" name="horizontal_anchor_point" value="1"/>
                <Option type="QString" name="joinstyle" value="bevel"/>
                <Option type="QString" name="name" value="cross2"/>
                <Option type="QString" name="offset" value="0,0"/>
                <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="offset_unit" value="MM"/>
                <Option type="QString" name="outline_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
                <Option type="QString" name="outline_style" value="solid"/>
                <Option type="QString" name="outline_width" value="0"/>
                <Option type="QString" name="outline_width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="outline_width_unit" value="MM"/>
                <Option type="QString" name="scale_method" value="diameter"/>
                <Option type="QString" name="size" value="1.8"/>
                <Option type="QString" name="size_map_unit_scale" value="3x:0,0,0,0,0,0"/>
                <Option type="QString" name="size_unit" value="MM"/>
                <Option type="QString" name="vertical_anchor_point" value="1"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" name="name" value=""/>
                  <Option name="properties"/>
                  <Option type="QString" name="type" value="collection"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option type="QString" name="name" value=""/>
        <Option name="properties"/>
        <Option type="QString" name="type" value="collection"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol type="line" name="" alpha="1" is_animated="0" clip_to_extent="1" frame_rate="10" force_rhr="0">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" name="name" value=""/>
            <Option name="properties"/>
            <Option type="QString" name="type" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" id="{12e4e848-ea7a-4487-a67a-6da8d1f538b9}" locked="0" pass="0" class="SimpleLine">
          <Option type="Map">
            <Option type="QString" name="align_dash_pattern" value="0"/>
            <Option type="QString" name="capstyle" value="square"/>
            <Option type="QString" name="customdash" value="5;2"/>
            <Option type="QString" name="customdash_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="customdash_unit" value="MM"/>
            <Option type="QString" name="dash_pattern_offset" value="0"/>
            <Option type="QString" name="dash_pattern_offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="dash_pattern_offset_unit" value="MM"/>
            <Option type="QString" name="draw_inside_polygon" value="0"/>
            <Option type="QString" name="joinstyle" value="bevel"/>
            <Option type="QString" name="line_color" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
            <Option type="QString" name="line_style" value="solid"/>
            <Option type="QString" name="line_width" value="0.26"/>
            <Option type="QString" name="line_width_unit" value="MM"/>
            <Option type="QString" name="offset" value="0"/>
            <Option type="QString" name="offset_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="offset_unit" value="MM"/>
            <Option type="QString" name="ring_filter" value="0"/>
            <Option type="QString" name="trim_distance_end" value="0"/>
            <Option type="QString" name="trim_distance_end_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_end_unit" value="MM"/>
            <Option type="QString" name="trim_distance_start" value="0"/>
            <Option type="QString" name="trim_distance_start_map_unit_scale" value="3x:0,0,0,0,0,0"/>
            <Option type="QString" name="trim_distance_start_unit" value="MM"/>
            <Option type="QString" name="tweak_dash_pattern_on_corners" value="0"/>
            <Option type="QString" name="use_custom_dash" value="0"/>
            <Option type="QString" name="width_map_unit_scale" value="3x:0,0,0,0,0,0"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" name="name" value=""/>
              <Option name="properties"/>
              <Option type="QString" name="type" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>1</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;

UPDATE sys_style AS t
SET stylevalue = v.stylevalue
FROM (
	VALUES
	('110', 've_node', '<!DOCTYPE qgis PUBLIC ''http://mrcc.com/qgis.dtd'' ''SYSTEM''>
<qgis labelsEnabled="0" version="3.40.8-Bratislava" styleCategories="Symbology|Labeling">
  <renderer-v2 symbollevels="0" type="RuleRenderer" referencescale="-1" enableorderby="0" forceraster="0">
    <rules key="{726173c1-e48a-4505-bde5-b50ffb7bba39}">
      <rule key="{7338027f-8cbe-4d2a-ab38-d5a0dda7e41a}" label="Storage" filter="&quot;sys_type&quot; = ''STORAGE''" symbol="0" scalemaxdenom="25000"/>
      <rule key="{2ad49ef6-10ef-413f-9dc9-82ff5a236362}" label="Chamber" filter="&quot;sys_type&quot; = ''CHAMBER''" symbol="1" scalemaxdenom="25000"/>
      <rule key="{fbe58f73-553d-4064-8e10-43eed3ee776f}" label="Wwtp" filter="&quot;sys_type&quot; = ''WWTP''" symbol="2" scalemaxdenom="25000"/>
      <rule key="{37713eda-5f1b-4684-a30c-22de38b168bd}" label="Netgully" filter="&quot;sys_type&quot; = ''NETGULLY''" symbol="3" scalemaxdenom="10000"/>
      <rule key="{21649539-e081-4b4c-8ee8-ea7124b229b5}" label="Netelement" filter="&quot;sys_type&quot; = ''NETELEMENT''" symbol="4" scalemaxdenom="10000"/>
      <rule key="{2bcc54c8-072d-493d-8ad6-14aa9d2013e7}" label="Manhole" filter="&quot;sys_type&quot; = ''MANHOLE''" symbol="5" scalemaxdenom="10000"/>
      <rule key="{c4d73b40-d93d-4ba0-b066-ff35c7a380fa}" label="Manhole" filter="&quot;sys_type&quot; = ''NETINIT''" symbol="6" scalemaxdenom="10000"/>
      <rule key="{010803db-b772-4cda-b196-1767fa88163b}" label="Wjump" filter="&quot;sys_type&quot; = ''WJUMP''" symbol="7" scalemaxdenom="10000"/>
      <rule key="{1aea5824-3d04-41eb-9016-bc26e1c51f00}" label="Junction" filter="&quot;sys_type&quot; = ''JUNCTION''" symbol="8" scalemaxdenom="10000"/>
      <rule key="{e40725c6-25ed-4c25-b0ff-07b0b77c60ea}" label="Valve" filter="&quot;sys_type&quot; = ''VALVE''" symbol="9" scalemaxdenom="10000"/>
      <rule key="{80f8584a-547c-4e05-8a9d-48fc73266e9e}" label="Outfall" filter="&quot;sys_type&quot; = ''OUTFALL''" symbol="10" scalemaxdenom="10000"/>
      <rule key="{9fabfc0f-4a2b-4f35-87d0-bfd160fe9be5}" label="OBSOLETE Header" filter="state=0 and sys_type IN (''STORAGE'', ''CHAMBER'', ''WWTP'')" symbol="11" scalemaxdenom="25000"/>
      <rule key="{ac1f6595-caf0-4334-97d8-7b2b589d74d9}" label="OBSOLETE" filter="state=0 and sys_type NOT IN (''STORAGE'', ''CHAMBER'', ''WWTP'')" symbol="12" scalemaxdenom="10000"/>
      <rule key="{bd611389-40fc-4567-8e48-ba1c5a524cc7}" label="PLANIFIED Header" filter="state=2 and sys_type IN (''STORAGE'', ''CHAMBER'', ''WWTP'')" symbol="13" scalemaxdenom="25000"/>
      <rule key="{fe8fe1e0-3b7c-4a26-9add-59a75fe66f9b}" label="PLANIFIED" filter="state=2 and sys_type NOT IN (''STORAGE'', ''CHAMBER'', ''WWTP'')" symbol="14" scalemaxdenom="10000"/>
      <rule key="{010c9edd-71a8-4314-9c57-8714f8e98de6}" label="PLANIFIED Header" filter="state=1 and p_state=0 and sys_type IN (''STORAGE'', ''CHAMBER'', ''WWTP'')" symbol="15" scalemaxdenom="25000"/>
      <rule key="{0d9d3dea-7928-4de4-b540-036653c10eb8}" label="PLANIFIED" filter="state=1 and p_state=0 and sys_type NOT IN (''STORAGE'', ''CHAMBER'', ''WWTP'')" symbol="16" scalemaxdenom="10000"/>
      <rule key="{c7afef7c-a29c-42aa-87ad-db98aa831c06}" label="(drawing)" filter="ELSE" symbol="17"/>
    </rules>
    <symbols>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="0" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{4139793a-18d0-4b5c-bc75-f41f3a7b5779}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="44,67,207,255,rgb:0.17254901960784313,0.2627450980392157,0.81176470588235294,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="coalesce(scale_polynomial(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0)"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="1" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{1179b589-e711-4659-b3d7-67d5f3da78f2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="31,120,180,255,rgb:0.12156862745098039,0.47058823529411764,0.70588235294117652,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="coalesce(scale_polynomial(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0)"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="10" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{d37e5a6f-35ff-4504-8e37-feea38bb15a2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="227,26,28,255,rgb:0.8901960784313725,0.10196078431372549,0.10980392156862745,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{97ab9d29-2fd7-4e6d-bc3e-f5fed256578d}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,255,255,255,hsv:0,0,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="equilateral_triangle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="255,255,255,0,rgb:1,1,1,0"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="coalesce(scale_polynomial(var(''map_scale''), 0, 10000, 3, 0.3, 0.37), 0)"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="11" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{4139793a-18d0-4b5c-bc75-f41f3a7b5779}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="120,120,120,153,rgb:0.4690928511482414,0.4690928511482414,0.4690928511482414,0.59999999999999998"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="120,120,120,153,rgb:0.4690928511482414,0.4690928511482414,0.4690928511482414,0.59999999999999998"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="coalesce(scale_polynomial(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0)"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="12" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{d37e5a6f-35ff-4504-8e37-feea38bb15a2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="120,120,120,153,rgb:0.4690928511482414,0.4690928511482414,0.4690928511482414,0.59999999999999998"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="120,120,120,153,rgb:0.4690928511482414,0.4690928511482414,0.4690928511482414,0.59999999999999998"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="13" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{4139793a-18d0-4b5c-bc75-f41f3a7b5779}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="44,67,207,0,rgb:0.17254901960784313,0.2627450980392157,0.81176470588235294,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="245,128,26,255,rgb:0.96078431372549022,0.50196078431372548,0.10196078431372549,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.5"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="coalesce(scale_polynomial(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0)"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="14" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{d37e5a6f-35ff-4504-8e37-feea38bb15a2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,0,rgb:0.41568627450980394,0.9137254901960784,1,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="245,128,26,255,rgb:0.96078431372549022,0.50196078431372548,0.10196078431372549,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.5"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="15" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{4139793a-18d0-4b5c-bc75-f41f3a7b5779}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="44,67,207,0,rgb:0.17254901960784313,0.2627450980392157,0.81176470588235294,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.5"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="coalesce(scale_polynomial(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0)"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="16" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{d37e5a6f-35ff-4504-8e37-feea38bb15a2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,0,rgb:0.41568627450980394,0.9137254901960784,1,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="121,208,255,255,rgb:0.47450980392156861,0.81568627450980391,1,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0.5"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="17" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{08733df3-bc13-4eac-bf5c-58b353a68ba7}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="85,95,105,255,hsv:0.58761111111111108,0.19267566948958573,0.41322957198443577,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="1.6"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="2" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{209eda1d-d4a0-438c-9173-3ef3ab79623a}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="50,48,55,255,rgb:0.19607843137254902,0.18823529411764706,0.21568627450980393,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="square"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="3"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="coalesce(scale_polynomial(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0)"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{4702f03f-33d6-4014-970d-18db360c593b}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.666667*(coalesce(scale_polynomial(var(''map_scale''), 0, 25000, 4.5, 0.5, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="3" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{44b56ed7-0be5-4cee-aee0-e9bb26e8ed60}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="129,10,78,0,rgb:0.50588235294117645,0.0392156862745098,0.30588235294117649,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="4" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{44b56ed7-0be5-4cee-aee0-e9bb26e8ed60}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="129,10,78,255,rgb:0.50588235294117645,0.0392156862745098,0.30588235294117649,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="5" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{d37e5a6f-35ff-4504-8e37-feea38bb15a2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="106,233,255,255,rgb:0.41568627450980394,0.9137254901960784,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="6" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{d37e5a6f-35ff-4504-8e37-feea38bb15a2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="26,115,162,255,rgb:0.10196078431372549,0.45098039215686275,0.63529411764705879,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="7" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{4bf54520-34f7-444b-ae0a-bf5c8d7c207c}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="147,218,255,255,rgb:0.57647058823529407,0.85490196078431369,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{01761201-7176-4576-9d02-30625002275d}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="147,218,255,255,rgb:0.57647058823529407,0.85490196078431369,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="0.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="8" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{0a9a2686-2556-4dc6-827c-3e56cbb69f62}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="45,136,255,255,rgb:0.17647058823529413,0.53333333333333333,1,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.37"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
        <layer locked="0" id="{adcb4267-a7be-4bab-afa4-94532d0b03e2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,0,rgb:1,0,0,0"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="0.5"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="0.25*(coalesce(scale_exp(var(''map_scale''), 0, 10000, 3.5, 0.3, 0.37), 0))"/>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="9" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{2d774c18-3b60-4c9e-9ecd-53008777ba97}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="0,0,0,255,rgb:0,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="255,255,255,255,rgb:1,1,1,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties" type="Map">
                <Option name="size" type="Map">
                  <Option name="active" type="bool" value="true"/>
                  <Option name="expression" type="QString" value="var(''map_scale'')"/>
                  <Option name="transformer" type="Map">
                    <Option name="d" type="Map">
                      <Option name="exponent" type="double" value="0.36999999999999994"/>
                      <Option name="maxSize" type="double" value="0.3"/>
                      <Option name="maxValue" type="double" value="10000"/>
                      <Option name="minSize" type="double" value="3.5"/>
                      <Option name="minValue" type="double" value="0"/>
                      <Option name="nullSize" type="double" value="0"/>
                      <Option name="scaleType" type="int" value="3"/>
                    </Option>
                    <Option name="t" type="int" value="1"/>
                  </Option>
                  <Option name="type" type="int" value="3"/>
                </Option>
              </Option>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <data-defined-properties>
      <Option type="Map">
        <Option name="name" type="QString" value=""/>
        <Option name="properties"/>
        <Option name="type" type="QString" value="collection"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol is_animated="0" force_rhr="0" frame_rate="10" name="" type="marker" alpha="1" clip_to_extent="1">
        <data_defined_properties>
          <Option type="Map">
            <Option name="name" type="QString" value=""/>
            <Option name="properties"/>
            <Option name="type" type="QString" value="collection"/>
          </Option>
        </data_defined_properties>
        <layer locked="0" id="{4dde61b6-903a-4c6e-b4dc-07a344b202e2}" class="SimpleMarker" pass="0" enabled="1">
          <Option type="Map">
            <Option name="angle" type="QString" value="0"/>
            <Option name="cap_style" type="QString" value="square"/>
            <Option name="color" type="QString" value="255,0,0,255,rgb:1,0,0,1"/>
            <Option name="horizontal_anchor_point" type="QString" value="1"/>
            <Option name="joinstyle" type="QString" value="bevel"/>
            <Option name="name" type="QString" value="circle"/>
            <Option name="offset" type="QString" value="0,0"/>
            <Option name="offset_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="offset_unit" type="QString" value="MM"/>
            <Option name="outline_color" type="QString" value="35,35,35,255,rgb:0.13725490196078433,0.13725490196078433,0.13725490196078433,1"/>
            <Option name="outline_style" type="QString" value="solid"/>
            <Option name="outline_width" type="QString" value="0"/>
            <Option name="outline_width_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="outline_width_unit" type="QString" value="MM"/>
            <Option name="scale_method" type="QString" value="diameter"/>
            <Option name="size" type="QString" value="2"/>
            <Option name="size_map_unit_scale" type="QString" value="3x:0,0,0,0,0,0"/>
            <Option name="size_unit" type="QString" value="MM"/>
            <Option name="vertical_anchor_point" type="QString" value="1"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option name="name" type="QString" value=""/>
              <Option name="properties"/>
              <Option name="type" type="QString" value="collection"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerGeometryType>0</layerGeometryType>
</qgis>')
) AS v(styleconfig_id, layername, stylevalue)
WHERE t.styleconfig_id::text = v.styleconfig_id AND t.layername = v.layername;