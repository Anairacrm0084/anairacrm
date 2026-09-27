'use client';
import {useParams} from 'next/navigation';
import PluginPage from '../../PluginPage';
export default function PluginRuntimePage(){const {pluginKey}=useParams();return <PluginPage pluginKey={pluginKey}/>;}
