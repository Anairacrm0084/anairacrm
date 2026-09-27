<?php
/**
 * Plugin Name: Anaira Hotel Booking Connector
 * Description: Connects WordPress hotel websites to the Anaira Supabase Booking Engine. Use [anaira_booking] to render the booking widget.
 * Version: 1.0.0
 * Author: Anaira Graphics & Digital Solution
 */
if (!defined('ABSPATH')) exit;

class Anaira_Hotel_Booking_Connector {
  const OPT = 'anaira_hbc_settings';
  public function __construct() {
    add_action('admin_menu', [$this,'menu']);
    add_action('admin_init', [$this,'settings']);
    add_shortcode('anaira_booking', [$this,'shortcode']);
  }
  public function menu() { add_options_page('Anaira Hotel Booking','Anaira Booking','manage_options','anaira-booking',[$this,'page']); }
  public function settings() {
    register_setting(self::OPT,self::OPT,['sanitize_callback'=>function($v){return [
      'url'=>esc_url_raw(trim($v['url']??'')), 'key'=>sanitize_text_field($v['key']??''), 'property_id'=>sanitize_text_field($v['property_id']??''),
      'title'=>sanitize_text_field($v['title']??'Hotel Booking'), 'accent'=>sanitize_hex_color($v['accent']??'#d6a63a') ?: '#d6a63a'
    ];}]);
  }
  public function page() { $s=get_option(self::OPT,[]); ?>
    <div class="wrap"><h1>Anaira Hotel Booking</h1><p>WordPress is the presentation/connector layer. Anaira Supabase remains the booking master.</p>
    <form method="post" action="options.php"><?php settings_fields(self::OPT); ?>
      <table class="form-table"><tr><th>Supabase URL</th><td><input class="regular-text" name="<?php echo esc_attr(self::OPT); ?>[url]" value="<?php echo esc_attr($s['url']??''); ?>" placeholder="https://your-project.supabase.co"></td></tr>
      <tr><th>Publishable Key</th><td><input class="large-text" name="<?php echo esc_attr(self::OPT); ?>[key]" value="<?php echo esc_attr($s['key']??''); ?>"></td></tr>
      <tr><th>Anaira Property ID</th><td><input class="regular-text" name="<?php echo esc_attr(self::OPT); ?>[property_id]" value="<?php echo esc_attr($s['property_id']??''); ?>" placeholder="UUID"></td></tr>
      <tr><th>Widget Title</th><td><input class="regular-text" name="<?php echo esc_attr(self::OPT); ?>[title]" value="<?php echo esc_attr($s['title']??'Hotel Booking'); ?>"></td></tr>
      <tr><th>Accent</th><td><input type="color" name="<?php echo esc_attr(self::OPT); ?>[accent]" value="<?php echo esc_attr($s['accent']??'#d6a63a'); ?>"></td></tr></table><?php submit_button('Save Anaira Connection'); ?></form>
    <hr><h2>Shortcode</h2><code>[anaira_booking]</code><p>Place it in Elementor/WordPress where the booking engine should appear.</p></div><?php }
  private function rpc($fn,$args) { $s=get_option(self::OPT,[]); if(empty($s['url'])||empty($s['key'])) return new WP_Error('not_configured','Anaira Booking connection is not configured.'); $url=rtrim($s['url'],'/').'/rest/v1/rpc/'.$fn; $r=wp_remote_post($url,['timeout'=>15,'headers'=>['apikey'=>$s['key'],'Authorization'=>'Bearer '.$s['key'],'Content-Type'=>'application/json'], 'body'=>wp_json_encode($args)]); if(is_wp_error($r)) return $r; $code=wp_remote_retrieve_response_code($r); $body=json_decode(wp_remote_retrieve_body($r),true); if($code>=300) return new WP_Error('anaira_api','Anaira API error',['status'=>$code,'body'=>$body]); return $body; }
  public function shortcode() { $s=get_option(self::OPT,[]); $property_id=$s['property_id']??''; if(!$property_id) return '<div class="anaira-booking-error">Anaira Booking is not configured.</div>'; $today=current_time('Y-m-d'); $in=date('Y-m-d',strtotime('+1 day',strtotime($today))); $out=date('Y-m-d',strtotime('+2 days',strtotime($today))); $rooms=$this->rpc('anaira_public_room_availability_by_id',['p_restaurant_id'=>$property_id,'p_check_in'=>$in,'p_check_out'=>$out,'p_adults'=>2,'p_children'=>0]); if(is_wp_error($rooms)) $rooms=[]; ob_start(); ?>
    <div class="anaira-booking-widget" style="--anaira-accent:<?php echo esc_attr($s['accent']??'#d6a63a'); ?>">
      <h2><?php echo esc_html($s['title']??'Hotel Booking'); ?></h2><form class="anaira-booking-form" onsubmit="return false"><label>Check-in <input type="date" name="check_in" value="<?php echo esc_attr($in); ?>"></label><label>Check-out <input type="date" name="check_out" value="<?php echo esc_attr($out); ?>"></label><button type="button" class="anaira-check">Check Availability</button></form>
      <div class="anaira-room-results"><?php if(!$rooms): ?><p>No rooms available for the selected dates.</p><?php else: foreach($rooms as $room): ?><article class="anaira-room"><div><strong><?php echo esc_html($room['name']??'Room'); ?></strong><small>Up to <?php echo esc_html($room['max_occupancy']??2); ?> guests · <?php echo esc_html($room['available_rooms']??0); ?> available</small></div><b>₹<?php echo esc_html(number_format((float)($room['base_rate']??0),2)); ?></b></article><?php endforeach; endif; ?></div>
    </div>
    <style>.anaira-booking-widget{border:1px solid #d8d0bb;border-radius:16px;padding:24px;background:#fffdf7;max-width:900px}.anaira-booking-widget h2{margin-top:0}.anaira-booking-form{display:grid;grid-template-columns:1fr 1fr auto;gap:12px;align-items:end}.anaira-booking-form label{display:grid;gap:6px;font-size:13px}.anaira-booking-form input{padding:11px;border:1px solid #d8d0bb;border-radius:8px}.anaira-check{padding:12px 18px;border:0;border-radius:8px;background:var(--anaira-accent);cursor:pointer}.anaira-room{display:flex;justify-content:space-between;align-items:center;border-top:1px solid #eee5d4;padding:16px 0}.anaira-room small{display:block;color:#6c6c63;margin-top:5px}@media(max-width:700px){.anaira-booking-form{grid-template-columns:1fr}}</style>
    <?php return ob_get_clean(); }
}
new Anaira_Hotel_Booking_Connector();
